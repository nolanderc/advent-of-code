fn main() {
    use std::io::Read;
    let mut input = String::new();
    std::io::stdin().read_to_string(&mut input).unwrap();

    let count = input
        .lines()
        .filter(|line| {
            let (policy, password) = split_around(line, ':').unwrap();
            let policy = Policy::parse(policy).unwrap();
            verify(policy, password.trim())
        })
        .count();

    println!("{}", count);
}

#[derive(Debug)]
struct Policy {
    first: usize,
    second: usize,
    letter: char,
}

fn split_around(text: &str, ch: char) -> Option<(&str, &str)> {
    let (a, b) = text.split_at(text.find(ch)?);
    Some((a, &b[ch.len_utf8()..]))
}

impl Policy {
    pub fn parse(text: &str) -> Option<Policy> {
        let (first, text) = split_around(text, '-')?;
        let (second, letter) = split_around(text, ' ')?;

        Some(Policy {
            first: first.parse().ok()?,
            second: second.parse().ok()?,
            letter: letter.parse().ok()?,
        })
    }
}

fn verify(policy: Policy, password: &str) -> bool {
    let count = (password.chars().nth(policy.first - 1) == Some(policy.letter)) as usize
        + (password.chars().nth(policy.second - 1) == Some(policy.letter)) as usize;
    count == 1
}
