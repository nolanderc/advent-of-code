use std::io::Read;

fn main() {
    let mut input = String::new();
    std::io::stdin().read_to_string(&mut input).unwrap();

    let instructions = input.lines().map(Instruction::parse).collect::<Vec<_>>();
    println!("{}", part1(&instructions));
    println!("{}", part2(&instructions));
}

fn part1(instructions: &[Instruction]) -> f64 {
    let mut x = 0.0;
    let mut y = 0.0;

    let mut dx = 1.0;
    let mut dy = 0.0;

    for instruction in instructions.iter() {
        let value = instruction.value as f64;
        match instruction.kind {
            InstructionKind::North => y += value,
            InstructionKind::South => y -= value,
            InstructionKind::East => x += value,
            InstructionKind::West => x -= value,
            InstructionKind::Left => rotate(&mut dx, &mut dy, value.to_radians()),
            InstructionKind::Right => rotate(&mut dx, &mut dy, -value.to_radians()),
            InstructionKind::Forward => {
                x += instruction.value as f64 * dx;
                y += instruction.value as f64 * dy;
            }
        }
    }

    x.abs() + y.abs()
}

fn part2(instructions: &[Instruction]) -> f64 {
    let mut x = 0.0;
    let mut y = 0.0;

    let mut dx = 10.0;
    let mut dy = 1.0;

    for instruction in instructions.iter() {
        let value = instruction.value as f64;
        match instruction.kind {
            InstructionKind::North => dy += value,
            InstructionKind::South => dy -= value,
            InstructionKind::East => dx += value,
            InstructionKind::West => dx -= value,
            InstructionKind::Left => rotate(&mut dx, &mut dy, value.to_radians()),
            InstructionKind::Right => rotate(&mut dx, &mut dy, -value.to_radians()),
            InstructionKind::Forward => {
                x += value * dx;
                y += value * dy;
            }
        }
    }

    x.abs() + y.abs()
}

fn rotate(x: &mut f64, y: &mut f64, angle: f64) {
    let (sin, cos) = angle.sin_cos();
    let new_x = *x * cos - *y * sin;
    let new_y = *x * sin + *y * cos;
    *x = new_x;
    *y = new_y;
}

struct Instruction {
    kind: InstructionKind,
    value: u32,
}

enum InstructionKind {
    North,
    South,
    East,
    West,
    Left,
    Right,
    Forward,
}

impl Instruction {
    pub fn parse(text: &str) -> Instruction {
        let (kind, arg) = text.split_at(1);
        let kind = match kind {
            "N" => InstructionKind::North,
            "S" => InstructionKind::South,
            "E" => InstructionKind::East,
            "W" => InstructionKind::West,
            "L" => InstructionKind::Left,
            "R" => InstructionKind::Right,
            "F" => InstructionKind::Forward,
            _ => panic!(),
        };
        let value = arg.parse().unwrap();
        Instruction { kind, value }
    }
}
