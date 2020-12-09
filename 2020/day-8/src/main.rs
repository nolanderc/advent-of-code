use regex::Regex;
use std::io::Read;

fn main() {
    let mut input = String::new();
    std::io::stdin().read_to_string(&mut input).unwrap();

    let instructions = parse_instructions(&input).unwrap();

    println!("{}", part1(&instructions));
    println!("{}", part2(&instructions));
}

fn part1(instructions: &[Instruction]) -> i32 {
    match execute(instructions) {
        Termination::Loop(value) => value,
        Termination::Terminate(value) => {
            eprintln!("Error: part1 terminated without infinite loop!");
            value
        }
    }
}

fn part2(instructions: &[Instruction]) -> i32 {
    for i in 0..instructions.len() {
        let new = match instructions[i] {
            Instruction::Jmp(value) => Instruction::Nop(value),
            Instruction::Nop(value) => Instruction::Jmp(value),
            _ => continue,
        };

        let mut tmp_instructions = instructions.to_vec();
        tmp_instructions[i] = new;

        match execute(&tmp_instructions) {
            Termination::Loop(_) => {}
            Termination::Terminate(value) => return value,
        }
    }

    eprintln!("could not fix part2 code");
    -1
}

enum Termination {
    Loop(i32),
    Terminate(i32),
}

fn execute(instructions: &[Instruction]) -> Termination {
    let mut visited = vec![false; instructions.len()];
    let mut i = 0i32;
    let mut acc = 0;

    while (i as usize) < instructions.len() {
        if visited[i as usize] {
            return Termination::Loop(acc);
        }

        visited[i as usize] = true;

        let mut jump = 1;
        match instructions[i as usize] {
            Instruction::Acc(delta) => acc += delta,
            Instruction::Nop(_) => {}
            Instruction::Jmp(offset) => jump = offset,
        }

        i += jump;
    }

    Termination::Terminate(acc)
}

#[derive(Debug, Copy, Clone)]
enum Instruction {
    Acc(i32),
    Jmp(i32),
    Nop(i32),
}

fn parse_instructions(text: &str) -> Option<Vec<Instruction>> {
    let regex = Regex::new(r"(\w{3}) ([+-]\d+)").unwrap();

    let mut instructions = Vec::new();
    for parts in regex.captures_iter(text) {
        let argument = parts[2].parse().ok()?;
        let instruction = match &parts[1] {
            "acc" => Instruction::Acc(argument),
            "jmp" => Instruction::Jmp(argument),
            "nop" => Instruction::Nop(argument),
            _ => unreachable!(),
        };
        instructions.push(instruction);
    }

    Some(instructions)
}
