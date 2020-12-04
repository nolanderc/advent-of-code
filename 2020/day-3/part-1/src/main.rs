fn main() {
    let count = std::io::BufRead::lines(std::io::stdin().lock())
        .map(Result::unwrap)
        .enumerate()
        .map(|(i, line)| line.chars().nth((3 * i) % line.chars().count()).unwrap())
        .filter(|&hit| hit == '#')
        .count();
    println!("{}", count);
}
