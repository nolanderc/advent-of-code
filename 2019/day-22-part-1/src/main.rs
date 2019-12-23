use std::fs;

#[derive(Debug, Copy, Clone)]
enum Shuffle {
    Reverse,
    Cut(isize),
    Incremental(usize),
}

fn main() {
    let input = fs::read_to_string("input").unwrap();
    let shuffles = parse_input(&input);

    let mut cards = create_deck(10007);

    for shuffle in shuffles {
        shuffle.apply(&mut cards);
    }

    let position = cards.into_iter().position(|i| i == 2019).unwrap();
    println!("Position: {}", position);
}

fn create_deck(count: u32) -> Vec<u32> {
    (0..count).collect()
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
                "cut" => Shuffle::Cut(argument.parse().unwrap()),
                _ => panic!("unknown kind: {}", kind),
            }
        })
        .collect()
}

impl Shuffle {
    pub fn apply(self, cards: &mut Vec<u32>) {
        match self {
            Shuffle::Reverse => cards.reverse(),
            Shuffle::Cut(size) => {
                let count = (cards.len() as isize + size) as usize % cards.len() as usize;
                let mut tail = cards.split_off(count);
                tail.append(cards);
                *cards = tail;
            }
            Shuffle::Incremental(step) => {
                let mut target = cards.clone();
                let mut i = 0;
                for card in cards.iter() {
                    target[i] = *card;
                    i = (i + step) % cards.len();
                }
                *cards = target;
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn example_1() {
        let mut cards = create_deck(10);
        let shuffles = parse_input(&fs::read_to_string("example_1").unwrap());
        shuffles
            .into_iter()
            .for_each(|shuffle| shuffle.apply(&mut cards));
        assert_eq!(cards, vec![0, 3, 6, 9, 2, 5, 8, 1, 4, 7])
    }

    #[test]
    fn example_2() {
        let mut cards = create_deck(10);
        let shuffles = parse_input(&fs::read_to_string("example_2").unwrap());
        shuffles
            .into_iter()
            .for_each(|shuffle| shuffle.apply(&mut cards));
        assert_eq!(cards, vec![3, 0, 7, 4, 1, 8, 5, 2, 9, 6])
    }

    #[test]
    fn example_3() {
        let mut cards = create_deck(10);
        let shuffles = parse_input(&fs::read_to_string("example_3").unwrap());
        shuffles
            .into_iter()
            .for_each(|shuffle| shuffle.apply(&mut cards));
        assert_eq!(cards, vec![6, 3, 0, 7, 4, 1, 8, 5, 2, 9])
    }

    #[test]
    fn example_4() {
        let mut cards = create_deck(10);
        let shuffles = parse_input(&fs::read_to_string("example_4").unwrap());
        shuffles
            .into_iter()
            .for_each(|shuffle| shuffle.apply(&mut cards));
        assert_eq!(cards, vec![9, 2, 5, 8, 1, 4, 7, 0, 3, 6])
    }
}
