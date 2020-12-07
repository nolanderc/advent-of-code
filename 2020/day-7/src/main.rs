use std::collections::{HashMap, HashSet};
use std::io::Read;

fn main() {
    let mut input = String::new();
    std::io::stdin().read_to_string(&mut input).unwrap();

    let bags = input
        .lines()
        .map(|line| {
            let (holder, contents) = split_around(line, "contain").unwrap();
            let holder = trim_bag(holder.trim());
            let contents = contents
                .split(|ch: char| ch.is_ascii_punctuation())
                .map(|entry| entry.trim())
                .filter(|s| !s.is_empty())
                .filter_map(|entry| match strip_count(entry) {
                    Some((count, kind)) => Some((count, trim_bag(kind.trim()))),
                    None if entry == "no other bags" => None,
                    _ => panic!("invalid bag entry: {:?}", entry),
                });

            (holder, contents.collect())
        })
        .collect::<Vec<_>>();

    let part1 = part1(&bags);
    let part2 = part2(&bags);

    println!("{}", part1);
    println!("{}", part2);
}

fn split_around<'a>(text: &'a str, sep: &str) -> Option<(&'a str, &'a str)> {
    let (a, b) = text.split_at(text.find(sep)?);
    Some((a, &b[sep.len()..]))
}

fn trim_bag(text: &str) -> &str {
    text.strip_suffix(" bags")
        .or_else(|| text.strip_suffix(" bag"))
        .unwrap_or(text)
}

fn strip_count(text: &str) -> Option<(usize, &str)> {
    let digits = text.chars().take_while(|ch| ch.is_ascii_digit()).count();
    let count = text[..digits].parse().ok()?;
    let rest = &text[digits..];
    Some((count, rest))
}

fn part1(bags: &[(&str, Vec<(usize, &str)>)]) -> usize {
    let mut can_contain = HashMap::new();
    for (holder, contents) in bags {
        for &(_count, contained) in contents {
            can_contain
                .entry(contained)
                .or_insert_with(HashSet::new)
                .insert(*holder);
        }
    }

    let mut parents = can_contain["shiny gold"]
        .iter()
        .copied()
        .collect::<HashSet<_>>();

    loop {
        let mut candidates = HashSet::new();
        for bag in parents.iter() {
            let outers = match can_contain.get(bag) {
                Some(parents) => parents,
                None => continue,
            };

            for outer in outers {
                if !parents.contains(outer) {
                    candidates.insert(outer);
                }
            }
        }

        if candidates.is_empty() {
            break;
        } else {
            parents.extend(candidates);
        }
    }

    parents.len()
}

fn part2(bags: &[(&str, Vec<(usize, &str)>)]) -> usize {
    let bags = bags
        .iter()
        .map(|(holder, contents)| (*holder, contents.as_slice()))
        .collect::<HashMap<_, _>>();

    let mut memo = HashMap::new();
    nested_bags("shiny gold", &bags, &mut memo)
}

// Count the number of bags using dynamic programming
fn nested_bags<'a>(
    bag: &'a str,
    bags: &'a HashMap<&str, &[(usize, &str)]>,
    memo: &mut HashMap<&'a str, usize>,
) -> usize {
    if let Some(cached) = memo.get(bag) {
        return *cached;
    }

    let mut total = 0;

    for &(count, child) in bags[bag].iter() {
        total += count * (1 + nested_bags(child, bags, memo));
    }

    memo.insert(bag, total);

    total
}
