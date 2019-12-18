use intcode::*;
use std::fs::*;

fn main() {
    let code = read_code();
    let best = chain_amps(&code, (0..=4).collect(), 0);

    println!("Maximum Thrustor: {}", best);
}

fn read_code() -> Vec<i32> {
    let text = read_to_string("input").unwrap();
    let mut lines = text.lines();

    lines
        .next()
        .unwrap()
        .split(',')
        .map(|w| w.parse().unwrap())
        .collect()
}

fn chain_amps(code: &Vec<i32>, phases: Vec<i32>, input: i32) -> i32 {
    (0..phases.len())
        .map(|i| {
            let mut phases = phases.clone();
            let phase = phases.swap_remove(i);
            let output = compute(code.clone(), vec![phase, input]);
            chain_amps(&code, phases, *output.last().unwrap())
        })
        .max()
        .unwrap_or(input)
}

#[test]
fn example_1() {
    let code = vec![
        3, 15, 3, 16, 1002, 16, 10, 16, 1, 16, 15, 15, 4, 15, 99, 0, 0,
    ];
    assert_eq!(chain_amps(&code, (0..=4).collect(), 0), 43210);
}

#[test]
fn example_2() {
    let code = vec![
        3, 23, 3, 24, 1002, 24, 10, 24, 1002, 23, -1, 23, 101, 5, 23, 23, 1, 24, 23, 23, 4, 23, 99,
        0, 0,
    ];
    assert_eq!(chain_amps(&code, (0..=4).collect(), 0), 54321);
}

#[test]
fn example_3() {
    let code = vec![
        3, 31, 3, 32, 1002, 32, 10, 32, 1001, 31, -2, 31, 1007, 31, 0, 33, 1002, 33, 7, 33, 1, 33,
        31, 31, 1, 32, 31, 31, 4, 31, 99, 0, 0, 0,
    ];
    assert_eq!(chain_amps(&code, (0..=4).collect(), 0), 65210);
}
