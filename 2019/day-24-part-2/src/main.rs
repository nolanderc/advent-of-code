use std::collections::*;
use std::fs;
use std::mem;

type State = HashSet<Location>;
type Location = (u8, u8, i32);

fn main() {
    let mut state = parse_input(&fs::read_to_string("input").unwrap());

    for _ in 0..200 {
        step(&mut state);
    }

    println!("Diversity: {}", state.len());
}

fn parse_input(text: &str) -> State {
    let mut bugs = HashSet::new();
    for (row, line) in text.trim().lines().enumerate() {
        for (col, ch) in line.chars().enumerate() {
            if ch == '#' {
                bugs.insert((col as u8, row as u8, 0));
            }
        }
    }
    bugs
}

fn step(state: &mut State) {
    let mut neighbours = HashMap::new();

    let old_state = mem::take(state);

    for &location in &old_state {
        for neighbour in adjacent(location) {
            *neighbours.entry(neighbour).or_insert(0) += 1;
        }
    }

    for (location, count) in neighbours {
        let alive = old_state.contains(&location);

        let keep_alive = alive && count == 1;
        let infest = !alive && (count == 1 || count == 2);

        if keep_alive || infest {
            state.insert(location);
        }
    }
}

fn adjacent((x, y, level): Location) -> impl Iterator<Item = Location> {
    let mut adjacent = Vec::new();

    let left = |v: u8, u: u8| {
        if v == 0 {
            vec![(1, 2, level - 1)]
        } else if v == 3 && u == 2 {
            (0..5).map(|u| (4, u, level + 1)).collect()
        } else {
            vec![(v - 1, u, level)]
        }
    };

    let right = |v: u8, u: u8| {
        if v == 1 && u == 2 {
            (0..5).map(|u| (0, u, level + 1)).collect()
        } else if v == 4 {
            vec![(3, 2, level - 1)]
        } else {
            vec![(v + 1, u, level)]
        }
    };

    adjacent.extend(left(x, y));
    adjacent.extend(right(x, y));

    let swap = |locations: Vec<_>| locations.into_iter().map(|(x, y, level)| (y, x, level));

    adjacent.extend(swap(left(y, x)));
    adjacent.extend(swap(right(y, x)));

    adjacent.into_iter()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn find_adjacent() {
        assert_eq!(
            adjacent((3, 2, 0)).collect::<BTreeSet<_>>(),
            vec![
                (3, 1, 0),
                (4, 2, 0),
                (3, 3, 0),
                (4, 0, 1),
                (4, 1, 1),
                (4, 2, 1),
                (4, 3, 1),
                (4, 4, 1),
            ]
            .into_iter()
            .collect::<BTreeSet<_>>()
        );

        assert_eq!(
            adjacent((4, 0, 0)).collect::<BTreeSet<_>>(),
            vec![(3, 0, 0), (4, 1, 0), (2, 1, -1), (3, 2, -1),]
                .into_iter()
                .collect::<BTreeSet<_>>()
        );
    }

    #[test]
    fn example_1() {
        let mut state = parse_input(&fs::read_to_string("example_1").unwrap());

        for _ in 0..10 {
            step(&mut state);
        }

        assert_eq!(state.len(), 99);
    }
}
