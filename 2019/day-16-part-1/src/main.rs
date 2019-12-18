use std::fs;
use std::iter;

fn main() {
    let input = load_input();
    let output = fft(input, 100);

    let output = output
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

fn fft(mut data: Vec<u8>, phases: usize) -> Vec<u8> {
    for _ in 0..phases {
        let mut result = data.clone();
        for (i, result) in result.iter_mut().enumerate() {
            let sequence = sequence(i);
            let sum = data
                .iter()
                .copied()
                .zip(sequence)
                .map(|(a, b)| a as i32 * b)
                .sum::<i32>();
            *result = (sum.abs() % 10) as u8;
        }

        data = result;
    }

    data
}

fn sequence(digit: usize) -> impl Iterator<Item = i32> {
    const BASE: &[i32] = &[0, 1, 0, -1];

    BASE.iter()
        .copied()
        .flat_map(move |value| iter::repeat(value).take(digit + 1))
        .cycle()
        .skip(1)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn example_1() {
        let data = parse_input("12345678");
        let output = fft(data, 4);
        assert_eq!(output, parse_input("01029498"));
    }

    #[test]
    fn example_2() {
        let data = parse_input("80871224585914546619083218645595");
        let output = fft(data, 100);
        assert_eq!(output[..8].to_vec(), parse_input("24176176"));
    }

    #[test]
    fn example_3() {
        let data = parse_input("19617804207202209144916044189917");
        let output = fft(data, 100);
        assert_eq!(output[..8].to_vec(), parse_input("73745418"));
    }

    #[test]
    fn example_4() {
        let data = parse_input("69317163492948606335995924319873");
        let output = fft(data, 100);
        assert_eq!(output[..8].to_vec(), parse_input("52432133"));
    }
}
