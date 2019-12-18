use std::io::*;

fn main() {
    let stdin = stdin();
    let mut lines = stdin.lock().lines().map(|line| line.unwrap());

    let ints = lines
        .next()
        .unwrap()
        .split(',')
        .map(|w| w.parse::<i32>().unwrap())
        .collect::<Vec<_>>();

    let input = lines
        .next()
        .unwrap()
        .split(',')
        .map(|w| w.parse::<i32>().unwrap())
        .collect::<Vec<_>>();

    let output = compute(ints, input.into_iter());
    println!("{:?}", output);
}

fn digit(value: i32, digit: u32) -> i32 {
    (value / 10i32.pow(digit)) % 10
}

fn read(code: &[i32], address: i32, mode: i32) -> i32 {
    let position = mode == 0;
    if position {
        code[address as usize]
    } else {
        address
    }
}

fn compute(mut code: Vec<i32>, mut input: impl Iterator<Item = i32>) -> Vec<i32> {
    let mut i = 0;
    let mut output = Vec::new();
    loop {
        let instruction = code[i];

        let a_mode = digit(instruction, 2);
        let b_mode = digit(instruction, 3);

        let op = instruction % 100;

        let size = match op {
            99 => break,
            // Add
            1 => {
                let a = read(&code, code[i + 1], a_mode);
                let b = read(&code, code[i + 2], b_mode);
                let target = code[i + 3];
                code[target as usize] = a + b;
                4
            }
            // Mul
            2 => {
                let a = read(&code, code[i + 1], a_mode);
                let b = read(&code, code[i + 2], b_mode);
                let target = code[i + 3];
                code[target as usize] = a * b;
                4
            }

            // Read input
            3 => {
                let target = code[i + 1];
                code[target as usize] = input.next().unwrap();
                2
            }

            // Write output
            4 => {
                let a = read(&code, code[i + 1], a_mode);
                output.push(a);
                2
            }

            _ => panic!("Invalid opcode: {}", op),
        };

        i += size;
    }

    output
}
