use std::collections::{HashMap, HashSet};
use std::io::Read;

fn main() {
    let mut input = String::new();
    std::io::stdin().read_to_string(&mut input).unwrap();

    let mut active = HashSet::new();
    let mut active_part2 = HashSet::new();

    for (row, line) in input.lines().enumerate() {
        for (col, ch) in line.chars().enumerate() {
            if ch == '#' {
                active.insert([row as i32, col as i32, 0i32]);
                active_part2.insert([row as i32, col as i32, 0i32, 0i32]);
            }
        }
    }

    println!("{}", simulate_cycles(active, part1));
    println!("{}", simulate_cycles(active_part2, part2));
}

fn simulate_cycles<T>(mut active: HashSet<T>, step: fn(&mut HashSet<T>)) -> usize {
    for _ in 0..6 {
        step(&mut active);
    }
    active.len()
}

fn part1(active: &mut HashSet<[i32; 3]>) {
    let mut neighbours = HashMap::new();

    for &[x, y, z] in active.iter() {
        for nx in x - 1..=x + 1 {
            for ny in y - 1..=y + 1 {
                for nz in z - 1..=z + 1 {
                    *neighbours.entry([nx, ny, nz]).or_insert(0) += 1;
                }
            }
        }
    }

    active.reserve(neighbours.len().saturating_sub(active.len()));

    for (position, count) in neighbours.into_iter() {
        if count == 3 || (count == 4 && active.contains(&position)) {
            active.insert(position);
        } else {
            active.remove(&position);
        }
    }
}

fn part2(active: &mut HashSet<[i32; 4]>) {
    let mut neighbours = HashMap::new();

    for &[x, y, z, w] in active.iter() {
        for nx in x - 1..=x + 1 {
            for ny in y - 1..=y + 1 {
                for nz in z - 1..=z + 1 {
                    for nw in w - 1..=w + 1 {
                        *neighbours.entry([nx, ny, nz, nw]).or_insert(0) += 1;
                    }
                }
            }
        }
    }

    for (position, count) in neighbours.into_iter() {
        if count == 3 || (count == 4 && active.contains(&position)) {
            active.insert(position);
        } else {
            active.remove(&position);
        }
    }
}
