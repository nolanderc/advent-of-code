use std::ops::RangeBounds as Range;

fn main() {
    let mut input = String::new();
    std::io::Read::read_to_string(&mut std::io::stdin(), &mut input).unwrap();

    let passports = input.split("\n\n").map(|passport| {
        passport
            .split_whitespace()
            .map(|pair| split_around(pair, ':').unwrap())
    });

    let mut valid_passports = 0;
    for passport in passports {
        let mut count = 0;
        let mut has_cid = false;
        let mut valid = true;
        for (key, value) in passport {
            count += 1;
            match key {
                "byr" => valid &= is_year(value, 1920..=2002),
                "iyr" => valid &= is_year(value, 2010..=2020),
                "eyr" => valid &= is_year(value, 2020..=2030),
                "hgt" => valid &= is_length(value, 150..=193, 59..=76),
                "hcl" => valid &= is_color(value),
                "ecl" => valid &= is_eye_color(value),
                "pid" => valid &= is_passport_id(value),
                "cid" => has_cid = true,
                _ => panic!("unknown key: {:?}", key),
            }
        }

        valid &= count == 7 + has_cid as usize;
        valid_passports += valid as usize;
    }

    println!("{}", valid_passports);
}

fn split_around(text: &str, letter: char) -> Option<(&str, &str)> {
    let (a, b) = text.split_at(text.find(letter)?);
    Some((a, &b[letter.len_utf8()..]))
}

macro_rules! ok_or {
    ($result:expr => $else:expr) => {
        match $result {
            Ok(value) => value,
            Err(_) => $else,
        }
    };
}

fn is_year(value: &str, range: impl Range<i32>) -> bool {
    range.contains(&ok_or!(value.parse() => return false))
}

fn is_length(value: &str, cm_range: impl Range<i32>, in_range: impl Range<i32>) -> bool {
    if let Some(prefix) = value.strip_suffix("cm") {
        cm_range.contains(&ok_or!(prefix.parse() => return false))
    } else if let Some(prefix) = value.strip_suffix("in") {
        in_range.contains(&ok_or!(prefix.parse() => return false))
    } else {
        false
    }
}

fn is_color(value: &str) -> bool {
    let bytes = value.as_bytes();
    bytes.len() == 7
        && bytes[0] == b'#'
        && bytes[1..]
            .iter()
            .all(|ch| matches!(ch, b'0'..=b'9' | b'a'..=b'f'))
}

fn is_eye_color(value: &str) -> bool {
    matches!(value, "amb" | "blu" | "brn" | "gry" | "grn" | "hzl" | "oth")
}

fn is_passport_id(value: &str) -> bool {
    let bytes = value.as_bytes();
    bytes.len() == 9 && bytes.iter().all(|ch| ch.is_ascii_digit())
}
