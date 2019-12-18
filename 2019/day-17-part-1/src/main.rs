use intcode::*;
use std::collections::*;

#[derive(Debug, Copy, Clone, PartialEq, Eq)]
enum Tile {
    Open,
    Scaffold,
    Robot(Direction),
    Death,
}

#[derive(Debug, Copy, Clone, PartialEq, Eq)]
enum Direction {
    Up,
    Left,
    Down,
    Right,
}

fn main() {
    let mut ascii = Computer::load("input").unwrap();

    let mut map = HashMap::new();

    let mut x = 0;
    let mut y = 0;
    loop {
        match ascii.run() {
            Action::NeedsInput => panic!("Needs input"),
            Action::Output(value) => {
                if value == 10 {
                    println!();
                    y += 1;
                    x = 0;
                } else {
                    print!("{}", value as u8 as char);

                    let tile = match value as u8 {
                        b'.' => Tile::Open,
                        b'#' => Tile::Scaffold,
                        b'^' => Tile::Robot(Direction::Up),
                        b'>' => Tile::Robot(Direction::Right),
                        b'v' => Tile::Robot(Direction::Down),
                        b'<' => Tile::Robot(Direction::Left),
                        b'X' => Tile::Death,
                        _ => unreachable!(),
                    };

                    map.insert([x, y], tile);
                    x += 1;
                }
            }
            Action::Halt => break,
        }
    }
    
    let mut sum = 0;

    for &[x, y] in map.keys() {
        let deltas = [[0, 1], [0, -1], [1, 0], [-1, 0]];

        let neighbours = deltas
            .iter()
            .filter(|&[dx, dy]| map.get(&[x + dx, y + dy]) == Some(&Tile::Scaffold))
            .count();

        if neighbours == 4 {
            sum += x * y;
        }
    }

    println!("{}", sum);
}
