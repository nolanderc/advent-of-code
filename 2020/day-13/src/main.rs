use std::io::Read;

fn main() {
    let mut input = String::new();
    std::io::stdin().read_to_string(&mut input).unwrap();

    let mut lines = input.lines();
    let arrival: u64 = lines.next().unwrap().parse().unwrap();
    let ids = lines
        .next()
        .unwrap()
        .split(',')
        .map(|id| id.parse::<u64>().ok())
        .collect::<Vec<_>>();

    println!("{}", part1(arrival, &ids));
    println!("{}", part2(&ids));
}

fn part1(arrival: u64, ids: &[Option<u64>]) -> u64 {
    let (best_bus, delay) = ids
        .iter()
        .filter_map(|&id| id)
        .map(|id| (id, (1 + arrival / id) * id - arrival))
        .min_by_key(|bus| bus.1)
        .unwrap();
    best_bus * delay
}

fn part2(ids: &[Option<u64>]) -> u64 {
    let mut equations = Vec::new();

    for (i, &id) in ids.iter().enumerate() {
        let id = match id {
            None => continue,
            Some(id) => id,
        };

        let i = i as u64;
        equations.push(Equation {
            base: id,
            value: (id - i % id) % id,
        });
    }

    chinese_remainder(&equations)
}

#[derive(Debug)]
struct Equation {
    base: u64,
    value: u64,
}

fn chinese_remainder(equations: &[Equation]) -> u64 {
    let mut term = 0;
    let mut multiplier = 1;

    for eq in equations.iter() {
        let inv = inverse(multiplier as u64, eq.base) as i64;
        term += multiplier * inv * ((eq.value as i64 - term) % eq.base as i64);
        multiplier *= eq.base as i64;

        if term < 0 {
            term += (1 + term.abs() / multiplier) * multiplier;
        }
    }

    term as u64
}

fn inverse(value: u64, base: u64) -> u64 {
    for i in 1..base {
        if (value * i) % base == 1 {
            return i;
        }
    }

    panic!()
}
