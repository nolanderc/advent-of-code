//! Finding `N` numbers that sum up to 2020.

use std::collections::BTreeSet;
use std::io::Read;

fn main() {
    let mut input = String::new();
    std::io::stdin().read_to_string(&mut input).unwrap();

    let mut nums = input.lines().map(|line| line.parse().unwrap());

    let count = nums.next().unwrap() as usize;
    let mut numbers = nums.collect::<Vec<u64>>();
    numbers.sort_unstable();
    numbers.dedup();

    match find_sum(count, 2020, &numbers, &mut BTreeSet::new()) {
        None => println!("impossible"),
        Some(terms) => {
            let strings = terms.iter().map(ToString::to_string).collect::<Vec<_>>();
            println!("{} = {}", strings.join(" + "), terms.iter().sum::<u64>());
            println!(
                "{} = {}",
                strings.join(" * "),
                terms.iter().product::<u64>()
            );
        }
    }
}

fn find_sum(
    count: usize,
    target: u64,
    numbers: &[u64],
    forbidden: &mut BTreeSet<u64>,
) -> Option<Vec<u64>> {
    if count == 0 {
        return None;
    }

    let upper_bound = match numbers.binary_search(&target) {
        Ok(index) if count == 1 && !forbidden.contains(&target) => {
            return Some(vec![numbers[index]])
        }
        Ok(index) => index,
        Err(index) => index,
    };

    let numbers = &numbers[..upper_bound];
    for &num in numbers.iter().rev() {
        if !forbidden.insert(num) {
            continue;
        }

        if let Some(mut numbers) = find_sum(count - 1, target - num, numbers, forbidden) {
            numbers.push(num);
            return Some(numbers);
        }

        forbidden.remove(&num);
    }

    None
}
