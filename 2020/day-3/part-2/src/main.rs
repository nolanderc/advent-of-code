fn main() {
    let count = std::io::BufRead::lines(std::io::stdin().lock())
        .map(|line| line.unwrap().into_bytes())
        .enumerate()
        .map(|(i, row)| {
            let get = |index| row[index % row.len()] == b'#';
            [
                get(1 * i),
                get(3 * i),
                get(5 * i),
                get(7 * i),
                i % 2 == 0 && get(i / 2),
            ]
        })
        .fold([0; 5], |mut acc, elem| {
            acc.iter_mut().zip(&elem).for_each(|(a, &b)| *a += b as u64);
            acc
        })
        .iter()
        .product::<u64>();
    println!("{}", count);
}
