use std::collections::{HashMap, HashSet};
use std::io::Read;

fn main() {
    let mut input = String::new();
    std::io::stdin().read_to_string(&mut input).unwrap();

    let lines = input.trim().lines().map(|line| line.trim());

    let mut flipped = Vec::new();
    for line in lines {
        let mut bytes = line.as_bytes();

        let (mut x, mut y) = (0, 0);

        while !bytes.is_empty() {
            let (dy, dx, rest) = match bytes {
                [b's', b'e', rest @ ..] => (-1, 1, rest),
                [b's', b'w', rest @ ..] => (-1, -1, rest),
                [b'n', b'e', rest @ ..] => (1, 1, rest),
                [b'n', b'w', rest @ ..] => (1, -1, rest),
                [b'e', rest @ ..] => (0, 2, rest),
                [b'w', rest @ ..] => (0, -2, rest),
                _ => panic!(),
            };

            x += dx;
            y += dy;

            bytes = rest;
        }

        flipped.push((x, y));
    }

    let mut black = HashSet::new();
    for tile in flipped {
        if !black.insert(tile) {
            black.remove(&tile);
        }
    }

    println!("part 1: {}", black.len());
    println!("part 2: {}", part2(black));
}

type Tile = (i32, i32);

fn part2(mut black: HashSet<Tile>) -> usize {
    for _ in 0..100 {
        next_tiling(&mut black);
    }
    black.len()
}

fn next_tiling(black: &mut HashSet<Tile>) {
    let mut neighbours = HashMap::with_capacity(black.len() * 6);
    for (x, y) in black.iter() {
        const DELTAS: [Tile; 7] = [
            (0, 0),   // current
            (1, 1),   // ne
            (1, -1),  // nw
            (-1, 1),  // se
            (-1, -1), // sw
            (0, 2),   // e
            (0, -2),  // w
        ];

        for &(dy, dx) in DELTAS.iter() {
            *neighbours.entry((x + dx, y + dy)).or_insert(0) += 1;
        }
    }

    for (&tile, &count) in neighbours.iter() {
        if black.contains(&tile) {
            let count = count - 1;
            if count == 0 || count > 2 {
                black.remove(&tile);
            }
        } else if count == 2 {
            black.insert(tile);
        }
    }
}
