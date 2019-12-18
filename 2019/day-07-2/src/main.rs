use intcode::*;
use std::fs::*;

fn main() {
    let code = read_code();

    let best = best_combination(code);

    println!("Maximum Thrustor: {}", best);
}

fn best_combination(code: Vec<i32>) -> i32 {
    combinations((5..=9).collect())
        .map(|combination| feedback_amps(&code, combination))
        .max()
        .unwrap()
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

fn combinations(values: Vec<i32>) -> impl Iterator<Item = Vec<i32>> {
    (0..values.len()).flat_map(move |i| -> Box<dyn Iterator<Item = _>> {
        let mut values = values.clone();
        let last = values.swap_remove(i);

        if values.is_empty() {
            Box::new(Some(vec![last]).into_iter())
        } else {
            let combs = combinations(values).map(move |mut combination: Vec<i32>| {
                combination.push(last);
                combination
            });

            Box::new(combs)
        }
    })
}

fn feedback_amps(code: &Vec<i32>, phases: Vec<i32>) -> i32 {
    let mut input = 0;
    let mut last = 0;

    let mut amps = (0..5)
        .map(|_| Computer::new(code.to_vec()))
        .collect::<Vec<_>>();

    for (amp, phase) in amps.iter_mut().zip(phases) {
        amp.provide_input(Some(phase));
    }

    loop {
        for amp in &mut amps {
            amp.provide_input(Some(input));
            match amp.run() {
                Action::Halt => return last,
                Action::Output(output) => input = output,
                Action::NeedsInput => panic!("Insufficient input"),
            }
        }

        last = input;
    }
}

#[test]
fn simple_combination() {
    assert_eq!(
        combinations(vec![1, 2]).collect::<Vec<_>>(),
        vec![vec![2, 1], vec![1, 2],],
    );
}

#[test]
fn example_1() {
    let code = vec![
        3, 26, 1001, 26, -4, 26, 3, 27, 1002, 27, 2, 27, 1, 27, 26, 27, 4, 27, 1001, 28, -1, 28,
        1005, 28, 6, 99, 0, 0, 5,
    ];
    assert_eq!(best_combination(code), 139629729);
}

#[test]
fn example_2() {
    let code = vec![
        3, 52, 1001, 52, -5, 52, 3, 53, 1, 52, 56, 54, 1007, 54, 5, 55, 1005, 55, 26, 1001, 54, -5,
        54, 1105, 1, 12, 1, 53, 54, 53, 1008, 54, 0, 55, 1001, 55, 1, 55, 2, 53, 55, 53, 4, 53,
        1001, 56, -1, 56, 1005, 56, 6, 99, 0, 0, 0, 0, 10,
    ];
    assert_eq!(best_combination(code), 18216);
}
