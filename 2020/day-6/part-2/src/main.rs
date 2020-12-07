use std::collections::BTreeSet;
use std::io::Read;

fn main() {
    let mut input = String::new();
    std::io::stdin().read_to_string(&mut input).unwrap();

    let sum = input
        .split("\n\n")
        .filter_map(|group| {
            let answers = group
                .lines()
                .map(|person| person.chars().collect::<BTreeSet<_>>());

            fold_first(answers, |group, person| {
                group
                    .intersection(&person)
                    .copied()
                    .collect::<BTreeSet<_>>()
            })
        })
        .map(|group| group.len())
        .sum::<usize>();

    println!("{}", sum);
}

fn fold_first<T>(mut iter: impl Iterator<Item = T>, mut f: impl FnMut(T, T) -> T) -> Option<T> {
    let mut acc = iter.next()?;
    for x in iter {
        acc = f(acc, x);
    }
    Some(acc)
}
