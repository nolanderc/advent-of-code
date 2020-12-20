use std::collections::HashSet;
use std::io::Read;
use std::ops::RangeInclusive;

fn main() {
    let mut input = String::new();
    std::io::stdin().read_to_string(&mut input).unwrap();

    let mut lines = input.lines().map(|line| line.trim());

    // parse field schema
    let mut ranges = Vec::new();
    for line in lines.by_ref() {
        if line.is_empty() {
            break;
        }

        // parse fields
        let (name, range) = split_around(line, ": ");
        let (a, b) = split_around(range, " or ");
        ranges.push((parse_range(a), name));
        ranges.push((parse_range(b), name));
    }

    assert_eq!(lines.next(), Some("your ticket:"));
    let ticket = parse_ticket(lines.next().unwrap());
    assert_eq!(lines.next(), Some(""));

    let mut nearby = Vec::new();
    assert_eq!(lines.next(), Some("nearby tickets:"));
    for line in lines.by_ref() {
        nearby.push(parse_ticket(line))
    }

    println!("{}", part1(&ranges, &nearby));
    println!("{}", part2(&ranges, &nearby, &ticket));
}

fn part1(ranges: &[(RangeInclusive<u32>, &str)], nearby: &[Vec<u32>]) -> u32 {
    nearby
        .iter()
        .flat_map(|ticket| ticket.iter().copied())
        .filter(|field| find_range(ranges, *field).next().is_none())
        .sum()
}

fn part2(ranges: &[(RangeInclusive<u32>, &str)], nearby: &[Vec<u32>], ticket: &[u32]) -> u64 {
    let mut possibilities = collect_possibilities(ranges, ticket);

    for ticket in nearby.iter().filter(|ticket| valid_ticket(ticket, ranges)) {
        possibilities
            .iter_mut()
            .zip(collect_possibilities(ranges, ticket))
            .for_each(|(a, b)| *a = a.intersection(&b).copied().collect());
    }

    let mut fields = vec![""; ticket.len()];
    let mut locked = 0;
    'outer: while locked < ticket.len() {
        for (i, candidates) in possibilities.iter().enumerate() {
            if candidates.len() == 1 {
                let field = *candidates.iter().next().unwrap();
                for candidates in possibilities.iter_mut() {
                    candidates.remove(field);
                }

                fields[i] = field;
                locked += 1;

                continue 'outer;
            }
        }

        panic!("could not find unique field order");
    }

    fields
        .iter()
        .zip(ticket)
        .filter(|(name, _)| name.starts_with("departure"))
        .map(|(_, value)| *value as u64)
        .product()
}

fn collect_possibilities<'a>(
    ranges: &'a [(RangeInclusive<u32>, &'a str)],
    ticket: &[u32],
) -> Vec<HashSet<&'a str>> {
    let mut possibilities = Vec::with_capacity(ticket.len());

    for &field in ticket.iter() {
        possibilities.push(find_range(ranges, field).collect());
    }

    possibilities
}

fn valid_ticket(ticket: &[u32], ranges: &[(RangeInclusive<u32>, &str)]) -> bool {
    ticket
        .iter()
        .all(|field| find_range(ranges, *field).next().is_some())
}

fn find_range<'a>(
    ranges: &'a [(RangeInclusive<u32>, &'a str)],
    value: u32,
) -> impl Iterator<Item = &'a str> + 'a {
    ranges
        .iter()
        .filter(move |(range, _)| range.contains(&value))
        .map(|(_, name)| *name)
}

fn parse_ticket(line: &str) -> Vec<u32> {
    line.split(',').map(|w| w.parse().unwrap()).collect()
}

fn split_around<'a>(text: &'a str, sep: &str) -> (&'a str, &'a str) {
    let (a, b) = text.split_at(text.find(sep).unwrap());
    (a, &b[sep.len()..])
}

fn parse_range(text: &str) -> std::ops::RangeInclusive<u32> {
    let (start, end) = split_around(text, "-");
    start.parse().unwrap()..=end.parse().unwrap()
}
