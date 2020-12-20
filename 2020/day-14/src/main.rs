use std::collections::HashMap;
use std::io::Read;

fn main() {
    let mut input = String::new();
    std::io::stdin().read_to_string(&mut input).unwrap();

    let lines = input.lines().collect::<Vec<_>>();

    println!("{}", part1(&lines));
    println!("{}", part2(&lines));
}

fn part1(lines: &[&str]) -> u64 {
    let mut set = 0;
    let mut clear = 0;

    let mut memory = HashMap::new();

    for line in lines.iter().copied() {
        let (target, value) = split_around(line, " = ").unwrap();
        match target {
            "mask" => {
                let mut bit = 1 << 36;
                clear = 0;
                set = 0;
                for ch in value.chars() {
                    bit >>= 1;
                    match ch {
                        'X' => {}
                        '0' => clear |= bit,
                        '1' => set |= bit,
                        _ => unreachable!(),
                    }
                }
            }
            _ => {
                let address: u64 = target[4..target.len() - 1].parse().unwrap();
                let mut value: u64 = value.parse().unwrap();
                value |= set;
                value &= !clear;
                *memory.entry(address).or_default() = value;
            }
        }
    }

    memory.values().sum()
}

fn part2(lines: &[&str]) -> u64 {
    let mut memory = HashMap::new();

    let mut set = 0;
    let mut floating = vec![0];

    for line in lines.iter().copied() {
        let (target, value) = split_around(line, " = ").unwrap();
        match target {
            "mask" => {
                floating.truncate(1);
                let mut bit = 1 << 36;
                set = 0;
                for ch in value.chars() {
                    bit >>= 1;
                    match ch {
                        '0' => {}
                        '1' => set |= bit,
                        'X' => {
                            for i in 0..floating.len() {
                                floating.push(floating[i] | bit)
                            }
                        }
                        _ => unreachable!(),
                    }
                }
            }
            _ => {
                let mut address: u64 = target[4..target.len() - 1].parse().unwrap();
                let value: u64 = value.parse().unwrap();
                address |= set;
                for float in floating.iter() {
                    *memory.entry(address ^ float).or_default() = value;
                }
            }
        }
    }

    memory.values().sum()
}

fn split_around<'a>(text: &'a str, sep: &str) -> Option<(&'a str, &'a str)> {
    let (a, b) = text.split_at(text.find(sep)?);
    Some((a, &b[sep.len()..]))
}
