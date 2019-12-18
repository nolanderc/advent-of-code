use intcode::*;
use std::fs;
use std::path::Path;

fn main() {
    let code = read_code("input");

    let mut computer = Computer::new(code);
    computer.provide_input(Some(2));
    loop {
        match computer.run() {
            Action::Output(value) => println!("Output: {}", value),
            Action::Halt => break,
            Action::NeedsInput => panic!("needs more input"),
        }
    }
}

fn read_code(path: impl AsRef<Path>) -> Vec<i64> {
    let file = fs::read_to_string(path).unwrap();
    let line = file.lines().next().unwrap();
    line.split(',').map(|w| w.parse().unwrap()).collect()
}

#[test]
fn example_1() {
    let code = vec![
        109, 1, 204, -1, 1001, 100, 1, 100, 1008, 100, 16, 101, 1006, 101, 0, 99,
    ];
    let output = compute(code.clone(), vec![]);
    assert_eq!(code, output);
}

#[test]
fn example_2() {
    let code = vec![1102, 34915192, 34915192, 7, 4, 7, 99, 0];
    let output = compute(code, vec![]);
    let number = output.into_iter().next().unwrap();
    assert_eq!(number.to_string().len(), 16);
}

#[test]
fn example_3() {
    let code = vec![104, 1125899906842624, 99];
    let output = compute(code, vec![]);
    assert_eq!(output, vec![1125899906842624]);
}
