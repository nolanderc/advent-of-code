
use std::fs::*;

fn main() {
    let text = read_to_string("input.txt").unwrap();
    let mut sum = 0;
    for line in text.lines() {
        if line.is_empty() { continue }
        let weight = line.parse::<usize>().unwrap();
        sum += n / 3 - 2;
    }
    println!("{}", sum);
}
