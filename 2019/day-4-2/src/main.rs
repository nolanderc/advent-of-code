use std::collections::HashSet;
use std::io::*;

fn main() {
    let line = stdin()
        .lock()
        .lines()
        .map(|line| line.unwrap())
        .next()
        .unwrap();

    let mut ints = line.split('-');
    let start = ints.next().unwrap().parse::<u32>().unwrap();
    let end = ints.next().unwrap().parse::<u32>().unwrap();

    let count = (start..=end).filter(|i| is_valid(*i)).count();

    println!("{}", count);
}

fn is_valid(i: u32) -> bool {
    let digit = |n| (i / n) % 10;

    let digits = [
        digit(100000),
        digit(10000),
        digit(1000),
        digit(100),
        digit(10),
        digit(1),
    ];

    let same = digits
        .windows(2)
        .filter(|arr| arr[0] == arr[1])
        .map(|d| d[0]);
    let increasing = digits.windows(2).all(|arr| arr[0] <= arr[1]);
    let grouped = digits
        .windows(3)
        .filter(|d| d[0] == d[1] && d[1] == d[2])
        .map(|d| d[0]);

    let valid_groups = same
        .collect::<HashSet<_>>()
        .symmetric_difference(&grouped.collect())
        .count();

    valid_groups != 0 && increasing
}

#[test]
fn given() {
    assert!(!is_valid(111111));
    assert!(!is_valid(223450));
    assert!(!is_valid(123789));
    assert!(is_valid(112233));
    assert!(!is_valid(123444));
    assert!(is_valid(111122));
}
