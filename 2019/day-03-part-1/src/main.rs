
use std::io::*;
use std::collections::{HashMap, HashSet};

fn main() {
    let stdin = stdin();
    let stdin = stdin.lock();
    let mut lines = stdin.lines().map(|line| line.unwrap());
    let first = lines.next().unwrap();
    let second = lines.next().unwrap();

    let a = points(&first);
    let b = points(&second);

    let ap = a.keys().copied().collect::<HashSet<_>>();
    let bp = b.keys().copied().collect::<HashSet<_>>();

    let dist = ap.intersection(&bp)
        .map(|point| a[point] + b[point])
        .min()
        .unwrap();

    println!("{}", dist)
}

fn commands(line: &str) -> Vec<(u8, u32)> {
    line.split(',').map(|word| {
        let dir = word.as_bytes()[0];
        let dist = word[1..].parse().unwrap();
        (dir, dist)
    }).collect()
}

fn points(line: &str) -> HashMap<(i32, i32), usize> {
    let mut points = HashMap::new();

    let mut x = 0;
    let mut y = 0;
    let mut steps = 0;

    for (dir, dist) in commands(line) {
        let (dx, dy) = match dir {
            b'R' => (1, 0),
            b'L' => (-1, 0),
            b'D' => (0, -1),
            b'U' => (0, 1),
            _ => unreachable!(),
        };

        for _ in 0..dist {
            steps += 1;
            x += dx;
            y += dy;
            points.entry((x, y)).or_insert(steps);
        }
    }

    points
}

