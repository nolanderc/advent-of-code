use std::io::Read;

fn main() {
    let mut input = String::new();
    std::io::stdin().read_to_string(&mut input).unwrap();

    let adapters = input
        .lines()
        .map(|line| line.parse::<u32>().unwrap())
        .collect::<Vec<_>>();

    println!("{}", part1(adapters.clone()));
    println!("{}", part2(adapters.clone()));
}

fn part1(mut adapters: Vec<u32>) -> u32 {
    adapters.push(0);
    adapters.sort();

    let mut ones = 0;
    let mut threes = 1;
    for window in adapters.windows(2).rev() {
        match window[1] - window[0] {
            1 => ones += 1,
            3 => threes += 1,
            _ => {}
        }
    }

    ones * threes
}

fn part2(mut adapters: Vec<u32>) -> u64 {
    adapters.sort();
    let max_power = *adapters.last().unwrap();

    let mut powers = vec![0; 1 + max_power as usize];
    powers[0] = 1;

    for &adapter in adapters.iter() {
        for i in (1..=3.min(adapter as usize)).rev() {
            powers[adapter as usize] += powers[adapter as usize - i];
        }
    }

    powers[max_power as usize]
}
