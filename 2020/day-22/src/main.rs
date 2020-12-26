use std::collections::{HashMap, HashSet, VecDeque};
use std::io::Read;

fn main() {
    let mut input = String::new();
    std::io::stdin().read_to_string(&mut input).unwrap();

    let mut lines = input.lines().map(|line| line.trim());

    let mut next_player = || {
        let mut cards = VecDeque::new();
        let header = lines.next().unwrap();
        assert!(matches!(header, "Player 1:" | "Player 2:"));
        for line in lines.by_ref().take_while(|line| !line.is_empty()) {
            cards.push_back(line.parse::<Card>().unwrap());
        }
        cards
    };

    let players = [next_player(), next_player()];

    println!("{}", part1(players.clone()));
    println!("{}", part2(players));
}

type Card = u8;

fn part1(mut players: [VecDeque<Card>; 2]) -> u64 {
    let winner = loop {
        match (players[0].front(), players[1].front()) {
            (Some(_), None) => break &players[0],
            (None, Some(_)) => break &players[1],
            (None, None) => unreachable!(),
            (Some(_), Some(_)) => {
                let zero = players[0].pop_front().unwrap();
                let one = players[1].pop_front().unwrap();

                if zero > one {
                    players[0].push_back(zero);
                    players[0].push_back(one);
                } else {
                    players[1].push_back(one);
                    players[1].push_back(zero);
                }
            }
        }
    };

    score_deck(winner)
}

fn score_deck(cards: &VecDeque<Card>) -> u64 {
    cards
        .iter()
        .rev()
        .enumerate()
        .map(|(i, &card)| (i as u64 + 1) * card as u64)
        .sum()
}

fn part2(mut players: [VecDeque<Card>; 2]) -> u64 {
    match recursive_combat(&mut players) {
        Winner::Zero => score_deck(&players[0]),
        Winner::One => score_deck(&players[1]),
    }
}

#[derive(Debug, Copy, Clone)]
#[repr(u8)]
enum Winner {
    Zero,
    One,
}

fn recursive_combat(players: &mut [VecDeque<Card>; 2]) -> Winner {
    let mut previous_rounds = HashSet::new();

    loop {
        if players[0].is_empty() {
            break Winner::One;
        }
        if players[1].is_empty() {
            break Winner::Zero;
        }

        if !previous_rounds.insert(players.clone()) {
            break Winner::Zero;
        }

        let zero = players[0].pop_front().unwrap() as usize;
        let one = players[1].pop_front().unwrap() as usize;

        let winner;
        if zero <= players[0].len() && one <= players[1].len() {
            let mut decks = [
                players[0].iter().copied().take(zero).collect(),
                players[1].iter().copied().take(one).collect(),
            ];

            winner = recursive_combat(&mut decks);
        } else {
            if zero > one {
                winner = Winner::Zero;
            } else {
                winner = Winner::One;
            }
        }

        match winner {
            Winner::Zero => {
                players[0].push_back(zero as Card);
                players[0].push_back(one as Card);
            }
            Winner::One => {
                players[1].push_back(one as Card);
                players[1].push_back(zero as Card);
            }
        }
    }
}
