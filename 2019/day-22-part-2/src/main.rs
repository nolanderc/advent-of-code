use std::collections::*;
use std::fs;

#[derive(Debug, Copy, Clone)]
enum Shuffle {
    // new = len - previous - 1
    // =>
    // previous = len - new - 1
    // =>
    // previous = (-new - 1) % len
    // =>
    // previous = (new * inv(len - 1) - 1) % len
    // =>
    // previous = rotate(-1, incremental(len - 1, new))
    Reverse,
    // new = (previous - n) % len
    // =>
    // previous = (new + n) % len
    // =>
    // previous =
    Rotate(i64),
    // new = (previous * step) % len
    // =>
    // previous = (new * inv(step)) % len
    Incremental(u64),
}

fn main() {
    let input = fs::read_to_string("input").unwrap();
    let shuffles = parse_input(&input);

    let position = shuffle(2020, 119315717514047, &shuffles, 101741582076661);

    println!("Position: {}", position);
}

fn parse_input(text: &str) -> Vec<Shuffle> {
    text.trim()
        .lines()
        .map(|line| {
            let mut words = line.split_whitespace();
            let kind = words.next().unwrap();
            let argument = words.last().unwrap();
            match kind {
                "deal" => match argument.parse() {
                    Ok(cut) => Shuffle::Incremental(cut),
                    Err(_) if argument == "stack" => Shuffle::Reverse,
                    Err(e) => panic!("unknown argument: {}", e),
                },
                "cut" => Shuffle::Rotate(argument.parse().unwrap()),
                _ => panic!("unknown kind: {}", kind),
            }
        })
        .collect()
}

fn shuffle(target: u64, cards: u64, shuffles: &[Shuffle], repetitions: u64) -> u64 {
    let mut combination = Shuffle::combine(shuffles.iter().copied(), cards);

    let mut current = target;
    let mut reps = repetitions;

    while reps != 0 {
        if reps & 1 == 1 {
            current = combination.reverse(current, cards);
        }

        reps >>= 1;
        combination = combination.combine(combination, cards);
    }

    current
}

// next = previous * multiplier + offset
// =>
// previous = (next - offset) * inv(multiplier)
#[derive(Debug, Copy, Clone)]
struct Combined {
    multiplier: u64,
    offset: u64,
}

impl Combined {
    pub fn combine(self, other: Self, cards: u64) -> Self {
        Combined {
            multiplier: mul_mod(self.multiplier, other.multiplier, cards),
            offset: (mul_mod(self.offset, other.multiplier, cards) + other.offset) % cards,
        }
    }

    pub fn reverse(self, current: u64, cards: u64) -> u64 {
        let offset = current + cards - self.offset;
        mul_mod(offset, inverse(self.multiplier, cards), cards)
    }

    pub fn increment(self, step: u64, cards: u64) -> Combined {
        let Combined { multiplier, offset } = self;
        Combined {
            multiplier: mul_mod(multiplier, step, cards),
            offset: mul_mod(offset, step, cards),
        }
    }

    pub fn rotate(self, n: i64, cards: u64) -> Combined {
        let Combined { multiplier, offset } = self;
        let delta = (cards as i64 - n) as u64 % cards;
        Combined {
            multiplier,
            offset: (offset + delta) % cards,
        }
    }
}

impl Shuffle {
    pub fn combine(shuffles: impl IntoIterator<Item = Shuffle>, cards: u64) -> Combined {
        let mut combination = Combined {
            multiplier: 1,
            offset: 0,
        };

        for shuffle in shuffles {
            combination = match shuffle {
                Shuffle::Incremental(step) => combination.increment(step, cards),
                Shuffle::Rotate(n) => combination.rotate(n, cards),
                Shuffle::Reverse => combination.increment(cards - 1, cards).rotate(1, cards),
            };
        }

        combination
    }

    pub fn reverse(self, current: u64, cards: u64) -> u64 {
        match self {
            Shuffle::Reverse => Self::rotate(Self::increment(current, cards, cards - 1), cards, -1),
            Shuffle::Rotate(n) => Self::rotate(current, cards, n),
            Shuffle::Incremental(step) => Self::increment(current, cards, step),
        }
    }

    fn rotate(current: u64, cards: u64, n: i64) -> u64 {
        (current as i64 + cards as i64 + n) as u64 % cards
    }

    fn increment(current: u64, cards: u64, step: u64) -> u64 {
        let inv_step = inverse(step, cards) as u128;
        ((current as u128 * inv_step) % cards as u128) as u64
    }
}

/// Find the multiplicative inverse in modular arithmetic
fn inverse(x: u64, m: u64) -> u64 {
    let x = x as i64;
    let m = m as i64;
    let mut t = 0;
    let mut r = m;
    let mut new_t = 1;
    let mut new_r = x;
    while new_r != 0 {
        let q = r / new_r;
        let next_t = t - q * new_t;
        t = new_t;
        new_t = next_t;
        let next_r = r - q * new_r;
        r = new_r;
        new_r = next_r;
    }
    if r > 1 {
        panic!("{} is not invertible mod {}", x, m)
    }
    ((t + m) % m) as u64
}

/// Multiply in modular arithmetic without overflow
fn mul_mod(a: u64, b: u64, m: u64) -> u64 {
    ((a as u128 * b as u128) % m as u128) as u64
}

#[cfg(test)]
mod tests {
    use super::*;
    use Shuffle::*;

    #[test]
    fn reverse() {
        assert_eq!(shuffle(0, 10, &[Reverse], 1), 9);
    }

    #[test]
    fn cut() {
        assert_eq!(shuffle(0, 10, &[Rotate(4)], 1), 4);
        assert_eq!(shuffle(0, 10, &[Rotate(-4)], 1), 6);
    }

    #[test]
    fn incremental() {
        assert_eq!(shuffle(0, 10, &[Incremental(3)], 1), 0);
        assert_eq!(shuffle(2, 10, &[Incremental(3)], 1), 4);
    }

    #[test]
    fn part_1() {
        let shuffles = parse_input(&fs::read_to_string("input").unwrap());
        assert_eq!(shuffle(1234, 10007, &shuffles, 1), 2019);
    }
}
