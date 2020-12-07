use std::io::Read;

fn main() {
    let mut input = String::new();
    std::io::stdin().read_to_string(&mut input).unwrap();

    let sum = input
        .split("\n\n")
        .map(|group| {
            let mut questions = group
                .chars()
                .filter(|ch| !ch.is_ascii_whitespace())
                .collect::<Vec<_>>();
            questions.sort_unstable();
            questions.dedup();

            questions.len()
        })
        .sum::<usize>();

    println!("{}", sum);
}
