use std::collections::HashMap;
use std::io::Read;

fn main() {
    let mut input = String::new();
    std::io::stdin().read_to_string(&mut input).unwrap();

    let numbers = input
        .trim()
        .split(',')
        .map(|word| word.parse().unwrap())
        .collect::<Vec<_>>();

    println!("{}", game(&numbers, 2020));
    println!("{}", game(&numbers, 30000000));
}

fn game(numbers: &[u64], turns: u64) -> u64 {
    let highest = turns.max(numbers.iter().copied().max().unwrap_or(0));
    let mut memory = vec![!0; highest as usize];

    for (i, &number) in numbers.iter().enumerate() {
        memory[number as usize] = i as u64;
    }

    let mut previous = numbers.last().copied().unwrap_or(0);
    for i in numbers.len() as u64 - 1..turns - 1 {
        let previous_turn = std::mem::replace(&mut memory[previous as usize], i);
        previous = i.saturating_sub(previous_turn);
    }

    previous
}
