use intcode::*;
use std::collections::*;
use std::fs;

#[derive(Debug, Copy, Clone, PartialEq, Eq, Hash)]
struct Point {
    x: i32,
    y: i32,
}

#[derive(Debug, Copy, Clone, PartialEq, Eq, Hash)]
enum Color {
    Black = 0,
    White = 1,
}

struct Bot {
    computer: Computer,
    position: Point,
    direction: Point,
}

fn main() {
    let mut bot = Bot::new();

    let mut tiles = HashMap::new();

    loop {
        let position = bot.position;
        let current = tiles.get(&position).copied().unwrap_or(Color::White);
        match bot.paint_tile(current) {
            None => break,
            Some(color) => {
                tiles.insert(position, color);
            }
        }
    }

    let white = tiles
        .iter()
        .filter_map(|(position, color)| match color {
            Color::Black => None,
            Color::White => Some(position),
        })
        .collect::<Vec<_>>();

    let min_x = white.iter().map(|p| p.x).min().unwrap();
    let max_x = white.iter().map(|p| p.x).max().unwrap();
    let min_y = white.iter().map(|p| p.y).min().unwrap();
    let max_y = white.iter().map(|p| p.y).max().unwrap();

    let width = 1 + max_x - min_x;
    let height = 1 + max_y - min_y;

    let mut canvas = vec![vec!['.'; width as usize]; height as usize];

    for point in white {
        canvas[(height - 1 - (point.y - min_y)) as usize][(point.x - min_x) as usize] = '#';
    }

    for row in canvas {
        println!("{}", row.into_iter().collect::<String>());
    }

    println!("Colored tiles: {}", tiles.len());
}

impl Bot {
    pub fn new() -> Bot {
        let code = Self::load_code();
        let computer = Computer::new(code);

        let position = Point { x: 0, y: 0 };
        let direction = Point { x: 0, y: 1 };

        Bot {
            computer,
            position,
            direction,
        }
    }

    pub fn paint_tile(&mut self, previous: Color) -> Option<Color> {
        self.computer.provide_input(Some(previous as i64));

        let color = match self.computer.run() {
            Action::NeedsInput => panic!("Insufficient input"),
            Action::Halt => return None,
            Action::Output(color) => match color {
                0 => Color::Black,
                1 => Color::White,
                _ => unreachable!(),
            },
        };

        match self.computer.run() {
            Action::NeedsInput => panic!("Insufficient input"),
            Action::Halt => return None,
            Action::Output(direction) => match direction {
                0 => self.direction = self.direction.rotate_left(),
                1 => self.direction = self.direction.rotate_right(),
                _ => unreachable!(),
            },
        }

        self.position.x += self.direction.x;
        self.position.y += self.direction.y;

        Some(color)
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
}

impl Point {
    pub fn rotate_left(self) -> Self {
        Point {
            x: -self.y,
            y: self.x,
        }
    }

    pub fn rotate_right(self) -> Self {
        Point {
            x: self.y,
            y: -self.x,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn rotate_point() {
        assert_eq!(Point { x: 2, y: 1 }.rotate_left(), Point { x: -1, y: 2 });
        assert_eq!(Point { x: 2, y: 1 }.rotate_right(), Point { x: 1, y: -2 });
    }
}
