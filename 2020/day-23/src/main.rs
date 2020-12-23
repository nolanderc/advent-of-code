use std::io::Read;

fn main() {
    let mut input = String::new();
    std::io::stdin().read_to_string(&mut input).unwrap();

    let cups = input
        .trim()
        .bytes()
        .map(|b| (b - b'0') as u32)
        .collect::<Vec<_>>();

    println!("{}", part1(cups.clone()));
    println!("{}", part2(cups));
}

fn part1(cups: Vec<u32>) -> String {
    let cups = play_game(cups, 100);

    let mut out = String::with_capacity(cups.len());
    let one = cups.iter().position(|&cup| cup == 1).unwrap();
    for i in 1..cups.len() {
        out.push((b'0' + cups[(one + i) % cups.len()] as u8) as char);
    }
    out
}

fn part2(mut cups: Vec<u32>) -> u64 {
    cups.extend(10..=1_000_000);

    let cups = play_game(cups, 10_000_000);

    let one = cups.iter().position(|&cup| cup == 1).unwrap();
    let a = cups[(one + 1) % cups.len()] as u64;
    let b = cups[(one + 2) % cups.len()] as u64;
    a * b
}

#[derive(Copy, Clone)]
struct Cup {
    next: u32,
}

fn play_game(values: Vec<u32>, rounds: usize) -> Vec<u32> {
    let max_value = values.iter().copied().max().unwrap();

    let mut cups = vec![Cup { next: 0 }; 1 + max_value as usize];

    for (index, &value) in values.iter().enumerate() {
        cups[value as usize] = Cup {
            next: values[(index + 1) % values.len()],
        };
    }

    let mut current = values[0];

    for _ in 0..rounds {
        let mut removed = [0; 3];

        let mut next = cups[current as usize].next;
        for i in 0..3 {
            removed[i] = next;
            next = cups[next as usize].next;
        }

        let mut destination = current - 1;
        loop {
            if removed.contains(&destination) {
                destination -= 1;
            } else if destination == 0 {
                destination = max_value;
            } else {
                break;
            }
        }

        cups[current as usize].next = cups[removed[2] as usize].next;
        cups[removed[2] as usize].next = cups[destination as usize].next;
        cups[destination as usize].next = removed[0];

        current = cups[current as usize].next;
    }

    let mut values = Vec::with_capacity(values.len());
    values.push(1);

    let mut cup = &cups[1];

    while cup.next != 1 {
        values.push(cup.next);
        cup = &cups[cup.next as usize];
    }

    values
}
