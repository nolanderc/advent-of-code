use std::io::*;

fn main() {
    let ints = stdin()
        .lock()
        .lines()
        .next()
        .unwrap()
        .unwrap()
        .split(',')
        .map(|w| w.parse::<u32>().unwrap())
        .collect::<Vec<_>>();

    for n in 0..100 {
        for v in 0..100 {
            let mut ints = ints.clone();
            ints[1] = n;
            ints[2] = v;

            if compute(ints) == 19690720 {
                println!("{}", 100 * n + v);
                return;
            }
        }
    }
}


fn compute(mut ints: Vec<u32>) -> u32 {
    for i in (0..).step_by(4) {
        let op = ints[i];
        if op == 99 {
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
    }

    ints[0]
}

