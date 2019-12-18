use intcode::*;
use std::collections::*;
use std::fs;

use Direction::*;

#[derive(Debug, Copy, Clone, Hash, PartialEq, Eq)]
enum Direction {
    North = 1,
    South = 2,
    West = 3,
    East = 4,
}

#[derive(Debug, Copy, Clone, Hash, PartialEq, Eq)]
enum Tile {
    Wall,
    Open,
    Oxygen,
}

#[derive(Debug, Copy, Clone, PartialEq, Eq, Hash)]
struct Point {
    x: i32,
    y: i32,
}

const DIRS: [Direction; 4] = [North, South, West, East];

fn main() {
    let code = load_code();
    let mut remote = Computer::new(code);

    let mut grid: HashMap<Point, Tile> = HashMap::new();
    let mut path: Vec<Direction> = Vec::new();

    let mut position = Point { x: 0, y: 0 };
    let mut oxygen = None;

    grid.insert(position, Tile::Open);

    loop {
        let direction = DIRS.iter().find(|&&dir| {
            let delta = dir.cartesian();
            let new = Point {
                x: position.x + delta.x,
                y: position.y + delta.y,
            };

            !grid.contains_key(&new)
        });

        let (direction, push) = match direction {
            None => match path.pop() {
                Some(dir) => (dir.reverse(), false),
                None => break,
            },
            Some(&dir) => (dir, true),
        };

        remote.provide_input(Some(direction as i64));

        let tile = match remote.run() {
            Action::NeedsInput => panic!("Insuffucient input provided"),
            Action::Halt => panic!("Computer broke"),
            Action::Output(value) => match value {
                0 => Tile::Wall,
                1 => Tile::Open,
                2 => Tile::Oxygen,
                _ => unreachable!(),
            },
        };

        let delta = direction.cartesian();
        let destination = Point {
            x: position.x + delta.x,
            y: position.y + delta.y,
        };

        grid.insert(destination, tile);

        let update = match tile {
            Tile::Wall => false,
            Tile::Oxygen => {
                oxygen = Some(destination);
                true
            }
            Tile::Open => true,
        };

        if update {
            position = destination;
            if push {
                path.push(direction);
            }
        }
    }

    display_grid(&grid);

    let distance = bfs(&grid, oxygen.unwrap()).unwrap();

    println!("Distance: {}", distance);
}

fn bfs(grid: &HashMap<Point, Tile>, target: Point) -> Option<usize> {
    let start = Point { x: 0, y: 0 };

    let mut queue = VecDeque::new();
    queue.push_back((start, 0));

    let mut visited = HashSet::new();

    while let Some((next, distance)) = queue.pop_front() {
        if visited.insert(next) {
            for &dir in &DIRS {
                let delta = dir.cartesian();
                let destination = Point {
                    x: next.x + delta.x,
                    y: next.y + delta.y,
                };
                match grid.get(&destination) {
                    Some(Tile::Open) | Some(Tile::Oxygen) => {
                        if destination == target {
                            return Some(distance + 1);
                        } else {
                            queue.push_back((destination, distance + 1));
                        }
                    }
                    _ => {}
                }
            }
        }
    }

    None
}

impl Direction {
    pub fn cartesian(self) -> Point {
        match self {
            North => Point { x: 0, y: -1 },
            South => Point { x: 0, y: 1 },
            West => Point { x: -1, y: 0 },
            East => Point { x: 1, y: 0 },
        }
    }

    pub fn reverse(self) -> Direction {
        match self {
            North => South,
            South => North,
            West => East,
            East => West,
        }
    }
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

    let width = (max_x - min_x + 1) as usize;
    let height = (max_y - min_y + 1) as usize;

    let mut tiles = vec![vec!['.'; width]; height];

    for (point, &tile) in grid {
        let col = point.x - min_x;
        let row = point.y - min_y;

        tiles[row as usize][col as usize] = match tile {
            _ if point.x == 0 && point.y == 0 => 'X',
            Tile::Wall => '#',
            Tile::Open => ' ',
            Tile::Oxygen => 'O',
        };
    }

    for row in tiles {
        for tile in row {
            print!("{}", tile);
        }
        println!();
    }
}
