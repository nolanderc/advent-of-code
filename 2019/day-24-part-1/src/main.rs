use std::collections::*;
use std::fmt;
use std::fs;

#[derive(Debug, Copy, Clone, PartialEq, Eq, Hash)]
struct State(u32);

fn main() {
    let state = parse_input(&fs::read_to_string("input").unwrap());
    println!("{}", state);
    println!("Diversity: {}", find_recurrence(state).0);
}

fn parse_input(text: &str) -> State {
    let state = text
        .trim()
        .lines()
        .flat_map(|line| {
            line.chars().map(|ch| match ch {
                '#' => 1,
                '.' => 0,
                _ => panic!("Invalid tile"),
            })
        })
        .enumerate()
        .fold(0, |total, (i, value)| total | (value << i));
    State(state)
}

fn find_recurrence(mut state: State) -> State {
    let mut states = HashSet::new();
    while states.insert(state) {
        state = step(state);
    }
    state
}

fn step(old: State) -> State {
    let mut new = State(0);
    for row in 0..5 {
        for col in 0..5 {
            let adjacent = [
                old.get(row + 1, col),
                old.get(row.wrapping_sub(1), col),
                old.get(row, col + 1),
                old.get(row, col.wrapping_sub(1)),
            ];

            let neighbours = adjacent.iter().filter(|&&alive| alive).count();

            let alive = old.get(row, col);
            let kept_alive = alive && neighbours == 1;
            let infested = !alive && (neighbours == 1 || neighbours == 2);

            if kept_alive || infested {
                new.set(row, col, true);
            }
        }
    }

    new
}

impl fmt::Display for State {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        let State(state) = *self;
        writeln!(f, "{:b}", self.0)?;
        for row in 0..5 {
            for col in 0..5 {
                let alive = self.get(row, col);
                let ch = match alive {
                    true => '#',
                    false => '.',
                };
                write!(f, "{}", ch)?;
            }
            writeln!(f)?;
        }
        Ok(())
    }
}

impl State {
    pub fn get(self, row: usize, col: usize) -> bool {
        if row >= 5 || col >= 5 {
            false
        } else {
            let index = row * 5 + col;
            self.0 & (1 << index) != 0
        }
    }

    pub fn set(&mut self, row: usize, col: usize, value: bool) {
        if row >= 5 || col >= 5 {
            panic!("coordinate out of bounds");
        } else {
            let index = row * 5 + col;
            let mask = 1 << index;

            if value {
                self.0 |= mask;
            } else {
                self.0 &= !mask;
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn example_1() {
        let state = parse_input(&fs::read_to_string("example_1").unwrap());
        assert_eq!(find_recurrence(state).0, 2_129_920);
    }
}
