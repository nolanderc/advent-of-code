use std::io::Read;

fn main() {
    let mut input = String::new();
    std::io::stdin().read_to_string(&mut input).unwrap();

    let numbers = input
        .lines()
        .map(|line| line.parse::<u64>().unwrap())
        .collect::<Vec<_>>();

    let invalid = part1(&numbers).unwrap();
    println!("{}", invalid);
    println!("{}", part2(&numbers, invalid).unwrap());
}

fn part1(numbers: &[u64]) -> Option<u64> {
    for window in numbers.windows(25 + 1) {
        let (last, window) = window.split_last().unwrap();
        if !validate_window(window, *last) {
            return Some(*last);
        }
    }

    None
}

fn validate_window(window: &[u64], current: u64) -> bool {
    for (i, a) in window.iter().enumerate() {
        for b in window.iter().skip(i + 1) {
            if a + b == current && a != b {
                return true;
            }
        }
    }
    false
}

fn part2(numbers: &[u64], target: u64) -> Option<u64> {
    for i in 0..numbers.len()-2 {
        let mut sum = numbers[i];
        for j in i + 1..numbers.len() {
            sum += numbers[j];
            match sum.cmp(&target) {
                std::cmp::Ordering::Less => continue,
                std::cmp::Ordering::Greater => break,
                std::cmp::Ordering::Equal => {
                    let min = numbers[i..=j].iter().min()?;
                    let max = numbers[i..=j].iter().max()?;
                    return Some(min + max)
                },
            }
        }
    }

    None
}
