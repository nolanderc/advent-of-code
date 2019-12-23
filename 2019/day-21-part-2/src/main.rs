use intcode::*;
use std::convert::*;

fn main() {
    let mut droid = Computer::load("input").unwrap();


    let instructions = [
        "NOT D J",

        "OR E T",
        "OR H T",
        "NOT T T",
        "OR T J",

        "OR D T",
        "AND A T",
        "AND B T",
        "AND C T",
        "OR T J",

        "NOT J J",

        // Must be able to land
        "RUN",
    ];

    let program = instructions.join("\n") + "\n";

    droid.provide_input(program.bytes().map(|c| c as i64));

    loop {
        match droid.run() {
            Action::Halt => break,
            Action::NeedsInput => panic!("insufficent input"),
            Action::Output(value) => {
                match u8::try_from(value) {
                    Ok(ch) => match ch as char {
                        '\n' => println!(),
                        ch => print!("{}", ch),
                    }
                    Err(_) => println!("{}", value),
                }
            }
        }
    }
}

