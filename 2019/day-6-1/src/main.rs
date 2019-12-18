use std::collections::HashMap;
use std::io::*;

fn main() {
    let stdin = stdin();
    let lines = stdin.lock().lines().map(|l| l.unwrap());

    let edges = lines
        .map(|line| -> Option<_> {
            let mut planets = line.split(')');
            let parent = planets.next()?;
            let child = planets.next()?;
            Some((parent.to_owned(), child.to_owned()))
        })
        .take_while(|edge| edge.is_some())
        .map(Option::unwrap);

    let mut planets = HashMap::new();

    for (parent, child) in edges {
        planets.entry(parent).or_insert_with(Vec::new).push(child);
    }

    let count = count_orbits(&planets, "COM", 0);
    println!("Oribts: {}", count)
}

fn count_orbits(planets: &HashMap<String, Vec<String>>, current: &str, depth: usize) -> usize {
    let children = planets.get(current).map(|ch| ch.as_slice()).unwrap_or(&[]);

    let sum = children
        .iter()
        .map(|child| count_orbits(planets, child, depth + 1))
        .sum::<usize>();

    sum + depth
}
