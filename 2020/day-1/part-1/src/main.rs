use std::collections::BTreeSet;
use std::io::Read;

fn main() {
    let mut input = String::new();
    std::io::stdin().read_to_string(&mut input).unwrap();

    let numbers = input
        .lines()
        .map(|line| line.parse().unwrap())
        .collect::<BTreeSet<u64>>();

    let find_sum = |target: u64| {
        for &num in numbers.iter() {
            if target < num {
                break;
            }
            let other = target - num;
            if numbers.contains(&other) {
                return Some((num, other));
            }
        }
        None
    };

    let (a, b) = find_sum(2020).expect("could not find pair that adds to 2020");
    println!("{}", a * b);
}
