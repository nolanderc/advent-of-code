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
        planets.entry(child).or_insert(parent);
    }

    let santa = get_distances(&planets, "SAN");
    let you = get_distances(&planets, "YOU");

    let mut santa = santa.into_iter().collect::<Vec<_>>();
    santa.sort_by_key(|(_, distance)| *distance);

    let distance = santa
        .into_iter()
        .filter_map(|(planet, santa_distance)| {
            let you_distance = you.get(&planet)?;
            Some(santa_distance + you_distance)
        })
        .min()
        .unwrap();

    println!("Combined distance: {}", distance)
}

fn get_distances<'a>(
    planets: &'a HashMap<String, String>,
    mut current: &'a str,
) -> HashMap<&'a String, usize> {
    let mut distances = HashMap::new();

    let mut distance = 0;
    while let Some(parent) = planets.get(current) {
        distances.insert(parent, distance);
        current = &parent;
        distance += 1;
    }

    distances
}
