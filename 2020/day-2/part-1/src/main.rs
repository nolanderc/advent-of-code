fn main() {
    use std::io::Read;
    let mut input = String::new();
    std::io::stdin().read_to_string(&mut input).unwrap();

    let count = input
        .lines()
        .filter(|line| {
            let separator = line.find(':').unwrap();
            let (policy, password) = line.split_at(separator);
            let policy = Policy::parse(policy).unwrap();
            let password = password.trim();
            verify(policy, password)
        })
        .count();

    println!("{}", count);
}

struct Policy {
    min: usize,
    max: usize,
    letter: char,
}

impl Policy {
    pub fn parse(text: &str) -> Option<Policy> {
        let (counts, letter) = text.split_at(text.find(' ')?);
        let (min, max) = counts.split_at(counts.find('-')?);

        Some(Policy {
            min: min.parse().ok()?,
            max: max[1..].trim().parse().ok()?,
            letter: letter[1..].parse().ok()?,
        })
    }
}

fn verify(policy: Policy, password: &str) -> bool {
    let count = password.chars().filter(|ch| *ch == policy.letter).count();
    policy.min <= count && count <= policy.max
}
