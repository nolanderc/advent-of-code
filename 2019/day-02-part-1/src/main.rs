use std::io::*;

fn main() {
    let mut ints = stdin()
        .lock()
        .lines()
        .next()
        .unwrap()
        .unwrap()
        .split(',')
        .map(|w| w.parse::<u32>().unwrap())
        .collect::<Vec<_>>();

    for i in (0..).step_by(4) {
        let op = ints[i];
        if op == 99 {
            println!("{}", ints[0]);
            break;
        }

        let a = ints[ints[i + 1] as usize];
        let b = ints[ints[i + 2] as usize];

        let res = if op == 1 {
            a + b
        } else if op == 2 {
            a * b
        } else {
            unreachable!();
        };

        let target = ints[i + 3] as usize;
        ints[target] = res;

        eprintln!("{:?}", ints);
    }
}
