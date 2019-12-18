use std::io::*;

const WIDTH: usize = 25;
const HEIGHT: usize = 6;

fn main() {
    let stdin = stdin();
    let mut lines = stdin.lock().lines().map(|l| l.unwrap());

    let mut digits = lines.next().unwrap().into_bytes();
    for byte in &mut digits {
        *byte -= b'0';
    }

    let layers = digits.chunks(WIDTH * HEIGHT).collect::<Vec<_>>();

    let zero = layers
        .iter()
        .min_by_key(|layer| layer.iter().filter(|b| **b == 0).count())
        .unwrap();

    let ones = zero.iter().filter(|b| **b == 1).count();
    let twos = zero.iter().filter(|b| **b == 2).count();

    println!("twos * ones: {}", ones * twos);
}
