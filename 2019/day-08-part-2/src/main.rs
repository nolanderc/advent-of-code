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

    let mut image = vec![2; WIDTH * HEIGHT];

    for layer in layers {
        for (old, &new) in image.iter_mut().zip(layer) {
            if *old == 2 {
                *old = new
            }
        }
    }

    for row in image.chunks(WIDTH) {
        for &pixel in row {
            match pixel {
                0 => print!(" "),
                1 => print!("#"),
                2 => print!(" "),
                _ => unreachable!(),
            }
        }

        println!();
    }
}
