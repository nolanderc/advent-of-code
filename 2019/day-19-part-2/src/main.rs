use intcode::*;
use std::ops::Range;

const LIMIT: usize = 10_000;

const SIZE: usize = 100;

// approximate the line, is guaranteed to be inside the tractor beam (varies depending on input)
const RATIO: (usize, usize) = (20, 50);

fn main() {
    let computer = Computer::load("input").unwrap();

    draw_area(0..50, 0..100, &computer);

    let mut low = 50;
    let mut high = LIMIT;

    while low < high {
        let mid = (low + high) / 2;

        if find_top(mid, &computer).is_some() {
            high = mid;
        } else {
            low = mid + 1;
        }

        dbg!(low, high);
    }

    let high_y = find_top(high, &computer).unwrap();
    let high_score = high * LIMIT + high_y;

    eprintln!("{}", high_score);
}

fn find_top(x: usize, computer: &Computer) -> Option<usize> {
    let y = (x * RATIO.1) / RATIO.0;

    let mut bottom = y;
    while affected([x as i64, bottom as i64 + 1], &computer) {
        bottom += 1;
    }

    let right = x + SIZE - 1;

    if affected([right as i64, bottom as i64], &computer) {
        let mut top = bottom;

        while affected([right as i64, top as i64 - 1], &computer) {
            top -= 1;
        }

        if bottom - top >= SIZE - 1 {
            return Some(top);
        }
    }

    None
}

fn affected([x, y]: [i64; 2], computer: &Computer) -> bool {
    let mut instance = computer.clone();
    instance.provide_input(vec![x, y]);
    match instance.run() {
        Action::NeedsInput => panic!("insufficient input"),
        Action::Halt => panic!("program terminated"),
        Action::Output(value) => value == 1,
    }
}

fn draw_area(xs: Range<usize>, ys: Range<usize>, computer: &Computer) {
    for y in ys {
        for x in xs.clone() {
            if affected([x as i64, y as i64], computer) {
                print!("#");
            } else {
                print!(".");
            }
        }
        if y % 10 == 0 {
            print!("-{}", y);
        }
        println!();
    }

    for x in xs {
        if x % 10 == 0 {
            print!("|{:<9}", x);
        }
    }
    println!();
}
