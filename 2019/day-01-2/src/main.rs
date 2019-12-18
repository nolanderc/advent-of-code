
use std::fs::*;

fn main() {
    let text = read_to_string("input.txt").unwrap();
    let mut sum = 0;
    for line in text.lines() {
        if line.is_empty() { continue }
        let mut weight = line.parse::<usize>().unwrap();

        while weight > 0 {
            let fuel = (weight / 3).saturating_sub(2);
            sum += fuel;
            weight = fuel;
        }
    }
    println!("{}", sum);
}
