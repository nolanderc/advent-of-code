use intcode::*;

fn main() {
    let computer = Computer::load("input").unwrap();

    let mut points = 0;
    for y in 0..50 {
        for x in 0..50 {
            if affected([x, y], &computer) {
                print!("#");
                points += 1;
            } else {
                print!(".");
            }
        }
        println!();
    }

    println!("Points: {}", points);
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
