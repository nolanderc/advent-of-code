use std::io::Read;

fn main() {
    let mut input = String::new();
    std::io::stdin().read_to_string(&mut input).unwrap();

    let mut lines = input.trim().lines().map(|line| line.trim());
    let public_keys: [u64; 2] = [
        lines.next().unwrap().parse().unwrap(),
        lines.next().unwrap().parse().unwrap(),
    ];

    let mut value = 1;
    let mut loops = 0;
    while value != public_keys[0] {
        value = (value * 7) % 20201227;
        loops += 1;
    }

    dbg!(loops);

    let mut private = 1;
    for _ in 0..loops {
        private = (private * public_keys[1]) % 20201227;
    }

    dbg!(private);
}
