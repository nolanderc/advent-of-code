use std::fs;
use std::ops::Range;

fn main() {
    let input = load_input();
    let message = decode_message(input);

    let output = message
        .into_iter()
        .take(8)
        .fold(String::new(), |acc, digit| acc + &digit.to_string());

    println!("First eight digits: {}", output);
}

fn load_input() -> Vec<u8> {
    let text = fs::read_to_string("input").unwrap();
    parse_input(&text)
}

fn parse_input(text: &str) -> Vec<u8> {
    text.trim()
        .lines()
        .next()
        .unwrap()
        .trim()
        .bytes()
        .map(|b| b - b'0')
        .collect()
}

fn decode_message(data: Vec<u8>) -> Vec<u8> {
    let offset = data
        .iter()
        .copied()
        .take(7)
        .fold(0, |total, digit| total * 10 + digit as usize);

    let total_len = data.len() * 10_000;
    let total_data = data.into_iter().cycle().take(total_len).collect();

    fft(total_data, 100, offset..offset + 8)
}

fn fft(mut data: Vec<u8>, phase: usize, indices: Range<usize>) -> Vec<u8> {
    let offset = indices.start;
    let mut sum = data[offset..].iter().map(|a| *a as i32).sum::<i32>();

    for _ in 0..phase {
        let mut partial = sum;
        sum = 0;

        for previous in &mut data[offset..] {
            let value = (partial % 10) as u8;
            partial -= *previous as i32;
            *previous = value;
            sum += value as i32;
        }
    }

    data[indices].to_vec()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn example_2_1() {
        let data = parse_input("03036732577212944063491565474664");
        let message = decode_message(data);
        assert_eq!(message, parse_input("84462026"));
    }

    #[test]
    fn example_2_2() {
        let data = parse_input("02935109699940807407585447034323");
        let message = decode_message(data);
        assert_eq!(message, parse_input("78725270"));
    }

    #[test]
    fn example_2_3() {
        let data = parse_input("03081770884921959731165446850517");
        let message = decode_message(data);
        assert_eq!(message, parse_input("53553731"));
    }
}
