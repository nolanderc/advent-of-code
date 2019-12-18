use intcode::*;
use std::collections::*;
use std::fs;
use std::io::{stdin, stdout, Write};

#[derive(Debug, Copy, Clone)]
enum Command {
    Draw { point: Point, tile: Tile },
    Score(i64),
    PollInput,
}

#[derive(Debug, Copy, Clone, PartialEq, Eq, Hash)]
struct Point {
    x: i64,
    y: i64,
}

#[derive(Debug, Copy, Clone, PartialEq, Eq)]
enum Tile {
    Empty,
    Wall,
    Block,
    Horizontal,
    Ball,
}

fn main() {
    let code = load_code();
    let arcade = Computer::new(code);

    let mut grid = HashMap::new();

    let io = arcade.run_async();

    let next_command = || -> Option<Command> {
        let x = io.recv().ok()?;

        match x {
            Action::Halt => None,
            Action::NeedsInput => Some(Command::PollInput),
            Action::Output(x) => {
                let y = io.recv().ok()?.output();
                let t = io.recv().ok()?.output();

                if x == -1 && y == 0 {
                    Some(Command::Score(t))
                } else {
                    let point = Point { x, y };
                    let tile = match t {
                        0 => Tile::Empty,
                        1 => Tile::Wall,
                        2 => Tile::Block,
                        3 => Tile::Horizontal,
                        4 => Tile::Ball,
                        _ => unreachable!(),
                    };

                    Some(Command::Draw { point, tile })
                }
            }
        }
    };

    let mut ball = Point { x: 0, y: 0 };
    let mut paddle = Point { x: 0, y: 0 };

    let mut auto = 0;
    let mut ticks = 0;

    while let Some(command) = next_command() {
        match command {
            Command::Draw { point, tile } => {
                grid.insert(point, tile);

                match tile {
                    Tile::Ball => ball = point,
                    Tile::Horizontal => paddle = point,
                    _ => {}
                }
            }
            Command::Score(score) => {
                println!("Score: {}", score);
            }
            Command::PollInput => {
                let mut line = String::new();
                display_grid(&grid);
                let dir = loop {
                    if auto > 0 {
                        auto -= 1;
                        let dx = paddle.x - ball.x;
                        break if dx == 0 {
                            0
                        } else if dx > 0 {
                            -1
                        } else {
                            1
                        };
                    } else {
                        print!("Enter some input: ");
                        stdout().lock().flush().unwrap();

                        stdin().read_line(&mut line).unwrap();
                        let text = line.trim();
                        if let Ok(count) = text.parse::<usize>() {
                            auto = count;
                            continue;
                        };

                        break match text {
                            "l" => -1,
                            "r" => 1,
                            "n" => 0,
                            "" => {
                                auto = 1;
                                continue;
                            }
                            _ => continue,
                        };
                    }
                };

                io.send(dir).unwrap();
                ticks += 1;
            }
        }
    }

    println!("Game over! ({} ticks)", ticks);
    display_grid(&grid);
}

fn load_code() -> Vec<i64> {
    let text = fs::read_to_string("input").unwrap();
    text.lines()
        .next()
        .unwrap()
        .split(',')
        .map(|w| w.parse().unwrap())
        .collect()
}

fn display_grid(grid: &HashMap<Point, Tile>) {
    let min_x = grid.keys().map(|p| p.x).min().unwrap();
    let max_x = grid.keys().map(|p| p.x).max().unwrap();
    let min_y = grid.keys().map(|p| p.y).min().unwrap();
    let max_y = grid.keys().map(|p| p.y).max().unwrap();

    let width = (max_x - min_x) as usize;
    let height = (max_y - min_y) as usize;

    let mut map = vec![vec![Tile::Empty; width + 1]; height + 1];

    for (point, tile) in grid {
        let x = point.x - min_x;
        let y = point.y - min_y;
        map[y as usize][x as usize] = *tile;
    }

    for row in map {
        for tile in row {
            let ch = match tile {
                Tile::Empty => ' ',
                Tile::Wall => '█',
                Tile::Block => '#',
                Tile::Horizontal => '-',
                Tile::Ball => 'O',
            };

            print!("{}", ch);
        }

        println!();
    }
}
