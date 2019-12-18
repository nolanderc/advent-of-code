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
        digit(1),
        digit(10),
        digit(100),
        digit(1000),
        digit(10000),
        digit(100000),
    ];

    let same = digits.windows(2).any(|arr| arr[0] == arr[1]);
    let increasing = digits.windows(2).all(|arr| arr[0] <= arr[1]);

    same && increasing
}

#[test]
fn given() {
    assert!(is_valid(111111));
    assert!(!is_valid(223450));
    assert!(!is_valid(123789));
}
