use intcode::*;
use std::collections::*;

#[derive(Debug, Copy, Clone, PartialEq, Eq)]
enum Tile {
    Open,
    Scaffold,
    Drone(Direction),
    Death,
}

#[derive(Debug, Copy, Clone, PartialEq, Eq)]
enum Direction {
    Up,
    Left,
    Down,
    Right,
}

// Alt 1
//
//
// R,8,L,10,L,12,R,4,
// R,8,L,12,R,4,R,4,
// R,8,L,10,L,12,R,4,
// R,8,L,10,R,8,
// R,8,L,10,L,12,R,4,
// R,8,L,12,R,4,R,4,
// R,8,L,10,R,8,
// R,8,L,12,R,4,R,4,
// R,8,L,10,R,8,
// R,8,L,12,R,4,R,4,
//
// A:
// R,8,L,10,L,12,R,4,
//
// B:
// R,8,L,12,R,4,R,4,
//
// C:
// R,8,L,10,R,8,
//
// Sequence:
// A,B,A,C,A,B,C,B,C,B
//

fn main() {
    let mut ascii = Computer::load("input").unwrap();

    let mut map = HashMap::new();

    let mut x = 0;
    let mut y = 0;
    let mut moved = false;
    let mut dust = 0;

    let text = "\
                A,B,A,C,A,B,C,B,C,B\n\
                R,8,L,10,L,12,R,4\n\
                R,8,L,12,R,4,R,4\n\
                R,8,L,10,R,8\n\
                ";

    ascii.provide_input(text.chars().map(|ch| ch as u8 as i64));

    loop {
        match ascii.run() {
            Action::NeedsInput => {
                display_path(&map);
                ascii.provide_input(vec![b'n' as i64, b'\n' as i64]);
                moved = true;
            }
            Action::Output(value) => {
                if moved {
                    dust = value
                } else {
                    if value == 10 {
                        println!();
                        y += 1;
                        x = 0;
                    } else {
                        print!("{}", value as u8 as char);

                        let tile = match value as u8 {
                            b'.' => Tile::Open,
                            b'#' => Tile::Scaffold,
                            b'^' => Tile::Drone(Direction::Up),
                            b'>' => Tile::Drone(Direction::Right),
                            b'v' => Tile::Drone(Direction::Down),
                            b'<' => Tile::Drone(Direction::Left),
                            b'X' => Tile::Death,
                            _ => continue,
                        };

                        map.insert([x, y], tile);
                        x += 1;
                    }
                }
            }
            Action::Halt => break,
        }
    }

    println!("Dust: {}", dust);
}

fn display_path(map: &HashMap<[i32; 2], Tile>) {
    let (mut position, mut direction) = map
        .iter()
        .filter_map(|(position, tile)| match tile {
            Tile::Drone(dir) => Some((*position, *dir)),
            _ => None,
        })
        .next()
        .unwrap();

    let mut commands = Vec::new();

    #[derive(Debug)]
    enum Command {
        Left,
        Right,
        Forward(usize),
    }

    loop {
        let left = add(position, direction.left().cartesian());
        let right = add(position, direction.right().cartesian());

        direction = if map.get(&left) == Some(&Tile::Scaffold) {
            commands.push(Command::Left);
            direction.left()
        } else if map.get(&right) == Some(&Tile::Scaffold) {
            commands.push(Command::Right);
            direction.right()
        } else {
            break;
        };

        let mut steps = 0;
        loop {
            let new = add(position, direction.cartesian());
            if map.get(&new) != Some(&Tile::Scaffold) {
                break;
            } else {
                position = new;
                steps += 1;
            }
        }

        commands.push(Command::Forward(steps));
    }

    eprintln!("Commands:");
    for cmd in commands {
        match cmd {
            Command::Left => print!("L"),
            Command::Right => print!("R"),
            Command::Forward(steps) => print!("{}", steps),
        }
        print!(",");
    }
    println!();
}

impl Direction {
    pub fn cartesian(self) -> [i32; 2] {
        match self {
            Direction::Up => [0, -1],
            Direction::Left => [-1, 0],
            Direction::Down => [0, 1],
            Direction::Right => [1, 0],
        }
    }

    pub fn left(self) -> Direction {
        match self {
            Direction::Up => Direction::Left,
            Direction::Left => Direction::Down,
            Direction::Down => Direction::Right,
            Direction::Right => Direction::Up,
        }
    }

    pub fn right(self) -> Direction {
        match self {
            Direction::Left => Direction::Up,
            Direction::Down => Direction::Left,
            Direction::Right => Direction::Down,
            Direction::Up => Direction::Right,
        }
    }
}

fn add([a, b]: [i32; 2], [c, d]: [i32; 2]) -> [i32; 2] {
    [a + c, b + d]
}
