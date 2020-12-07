fn main() {
    std::io::BufRead::lines(std::io::stdin().lock())
        .map(Result::unwrap)
        .map(|line| {
            let mut splits = line.chars().map(|ch| match ch {
                'F' | 'L' => Split::Low,
                'B' | 'R' => Split::High,
                _ => panic!("not a valid partition: {:?}", ch),
            });

            let row = binary_partition(0, 127, splits.by_ref().take(7));
            let col = binary_partition(0, 7, splits.by_ref().take(3));

            row * 8 + col
        })
        .max()
        .into_iter()
        .for_each(|max| println!("{}", max))
}

enum Split {
    Low,
    High,
}

fn binary_partition(mut low: u32, mut high: u32, splits: impl Iterator<Item = Split>) -> u32 {
    for split in splits {
        let mid = (low + high) / 2;
        match split {
            Split::Low => high = mid,
            Split::High => low = mid + 1,
        }
    }
    assert_eq!(low, high, "could not partition {}..={}", low, high);
    low
}
