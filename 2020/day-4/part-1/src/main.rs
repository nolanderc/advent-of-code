fn main() {
    let mut input = String::new();
    std::io::Read::read_to_string(&mut std::io::stdin(), &mut input).unwrap();
    let input = input.trim();

    let mut pairs = input.split(|c: char| c.is_ascii_whitespace()).peekable();

    let mut passports = 0;
    while pairs.peek().is_some() {
        let mut count = 0;
        let mut has_cid = false;
        pairs
            .by_ref()
            .take_while(|pair| !pair.is_empty())
            .map(|pair| split_around(pair, ':').unwrap())
            .for_each(|(key, _value)| {
                count += 1;
                has_cid |= key == "cid";
            });

        if count == (7 + has_cid as usize) {
            passports += 1;
        }
    }

    println!("{}", passports);
}

fn split_around(text: &str, letter: char) -> Option<(&str, &str)> {
    let (a, b) = text.split_at(text.find(letter)?);
    Some((a, &b[letter.len_utf8()..]))
}
