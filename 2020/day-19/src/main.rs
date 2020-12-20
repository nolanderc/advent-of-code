use std::collections::{BTreeMap, BTreeSet};
use std::io::Read;

fn main() {
    let mut input = String::new();
    std::io::stdin().read_to_string(&mut input).unwrap();

    let mut lines = input.lines().map(|line| line.trim_end());

    let mut rules = BTreeMap::new();
    for line in lines.by_ref().take_while(|line| !line.is_empty()) {
        let (id, rule) = split_around(line, ": ").unwrap();
        let id = id.parse::<RuleId>().unwrap();
        let rule = Rule::parse(rule);
        rules.insert(id, rule);
    }

    let messages = lines.collect::<Vec<_>>();

    println!("{}", part1(&rules, &messages));
    println!("{}", part2(&rules, &messages));
}

fn part1(rules: &BTreeMap<RuleId, Rule>, messages: &[&str]) -> usize {
    let rule = &rules[&0];
    messages
        .iter()
        .filter(|message| rule.accepts(message.as_bytes(), &rules))
        .count()
}

fn part2(rules: &BTreeMap<RuleId, Rule>, messages: &[&str]) -> usize {
    let rule_42 = &rules[&42];
    let rule_31 = &rules[&31];

    let mut matches = BTreeSet::new();
    for message in messages {
        // rule 8 matches one or more of rule 42.
        // rule 11 matches one or more of rule 42 followed by that same number of rule 31.
        //
        // Abuse the fact that we have `0: 8 11` and no other rules reference rule 8 or 11
        // therefore we need to match some number `x` of occurances of rule 42 and then some number
        // `y` where `0 < y < x` occurances of rule 31
        let mut count_42 = 0;
        let mut count_31 = 0;

        let mut bytes = message.as_bytes();
        while let Some(rest) = rule_42.trim(bytes, rules) {
            bytes = rest;
            count_42 += 1;
        }
        while let Some(rest) = rule_31.trim(bytes, rules) {
            bytes = rest;
            count_31 += 1;
        }

        if bytes.is_empty() && 0 < count_31 && count_31 < count_42 {
            matches.insert(*message);
        }
    }

    let expected = vec![
        "bbabbbbaabaabba",
        "babbbbaabbbbbabbbbbbaabaaabaaa",
        "aaabbbbbbaaaabaababaabababbabaaabbababababaaa",
        "bbbbbbbaaaabbbbaaabbabaaa",
        "bbbababbbbaaaaaaaabbababaaababaabab",
        "ababaaaaaabaaab",
        "ababaaaaabbbaba",
        "baabbaaaabbaaaababbaababb",
        "abbbbabbbbaaaababbbbbbaaaababb",
        "aaaaabbaabaaaaababaa",
        "aaaabbaabbaaaaaaabbbabbbaaabbaabaaa",
        "aabbbbbaabbbaaaaaabbbbbababaaaaabbaaabba",
    ]
    .into_iter()
    .collect::<BTreeSet<_>>();

    for diff in expected.symmetric_difference(&matches) {
        // diff;
    }

    matches.len()
}

type RuleSet = BTreeMap<RuleId, Rule>;

fn split_around<'a>(text: &'a str, sep: &str) -> Option<(&'a str, &'a str)> {
    let (a, b) = text.split_at(text.find(sep)?);
    Some((a, &b[sep.len()..]))
}

#[derive(Debug)]
enum Rule {
    Byte(u8),
    Sequence(Vec<RuleId>),
    Or(Box<Rule>, Box<Rule>),
}

type RuleId = usize;

impl Rule {
    pub fn parse(text: &str) -> Rule {
        if text.starts_with('"') {
            let mut chars = text.bytes();
            assert_eq!(chars.next(), Some(b'"'));
            let byte = chars.next().unwrap();
            assert_eq!(chars.next(), Some(b'"'));
            assert_eq!(chars.next(), None);
            Rule::Byte(byte)
        } else {
            match split_around(text, " | ") {
                Some((a, b)) => {
                    let left = Rule::parse(a);
                    let right = Rule::parse(b);
                    Rule::Or(left.into(), right.into())
                }
                None => {
                    let sequence = text.split_whitespace().map(|word| word.parse().unwrap());
                    Rule::Sequence(sequence.collect())
                }
            }
        }
    }

    pub fn accepts(&self, message: &[u8], rules: &RuleSet) -> bool {
        self.trim(message, rules) == Some(b"")
    }

    fn trim<'a>(&self, mut message: &'a [u8], rules: &RuleSet) -> Option<&'a [u8]> {
        match self {
            Rule::Byte(byte) => {
                let (first, rest) = message.split_first()?;
                if byte == first {
                    Some(rest)
                } else {
                    None
                }
            }
            Rule::Sequence(sequence) => {
                for id in sequence.iter() {
                    message = rules[id].trim(message, rules)?;
                }
                Some(message)
            }
            Rule::Or(a, b) => a.trim(message, rules).or_else(|| b.trim(message, rules)),
        }
    }
}
