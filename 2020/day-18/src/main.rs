use std::io::Read;

fn main() {
    let mut input = String::new();
    std::io::stdin().read_to_string(&mut input).unwrap();

    let exprs_part1 = input.lines().map(parse(parse_expr_part1));
    let exprs_part2 = input.lines().map(parse(parse_expr_part2));

    println!("{}", exprs_part1.map(|e| e.evaluate()).sum::<i64>());
    println!("{}", exprs_part2.map(|e| e.evaluate()).sum::<i64>());
}

#[derive(Debug)]
enum Expr {
    Term(i64),
    Parens(Box<Expr>),
    Add(Box<Expr>, Box<Expr>),
    Mul(Box<Expr>, Box<Expr>),
}

fn parse(parse_expr: fn(&[u8]) -> (Expr, &[u8])) -> impl Fn(&str) -> Expr {
    move |line| {
        let tokens = line
            .bytes()
            .filter(|ch| !ch.is_ascii_whitespace())
            .collect::<Vec<_>>();
        let (expr, remaining) = parse_expr(&tokens);
        assert!(remaining.is_empty());
        expr
    }
}

fn parse_expr_part1(tokens: &[u8]) -> (Expr, &[u8]) {
    let (mut lhs, mut tokens) = parse_term(tokens, parse_expr_part1);

    loop {
        match tokens {
            [b'+', rest @ ..] => {
                let (rhs, rest) = parse_term(rest, parse_expr_part1);
                tokens = rest;
                lhs = Expr::Add(lhs.into(), rhs.into())
            }
            [b'*', rest @ ..] => {
                let (rhs, rest) = parse_term(rest, parse_expr_part1);
                tokens = rest;
                lhs = Expr::Mul(lhs.into(), rhs.into())
            }
            _ => break (lhs, tokens),
        }
    }
}

fn parse_term(tokens: &[u8], parse_expr: fn(&[u8]) -> (Expr, &[u8])) -> (Expr, &[u8]) {
    match tokens {
        [b'(', rest @ ..] => {
            let (expr, rest) = parse_expr(rest);
            match rest {
                [b')', rest @ ..] => (Expr::Parens(expr.into()), rest),
                _ => panic!("unbalanced parens"),
            }
        }
        [number, rest @ ..] if number.is_ascii_digit() => (Expr::Term((number - b'0') as _), rest),
        _ => panic!("not a valid term: {:?}", tokens),
    }
}

fn parse_expr_part2(tokens: &[u8]) -> (Expr, &[u8]) {
    let (mut lhs, mut tokens) = parse_term(tokens, parse_expr_part2);

    loop {
        match tokens {
            [b'+', rest @ ..] => {
                let (rhs, rest) = parse_term(rest, parse_expr_part2);
                tokens = rest;

                lhs = match lhs {
                    Expr::Mul(lhs1, lhs2) => Expr::Mul(lhs1, Expr::Add(lhs2, rhs.into()).into()),
                    _ => Expr::Add(lhs.into(), rhs.into()),
                };
            }
            [b'*', rest @ ..] => {
                let (rhs, rest) = parse_term(rest, parse_expr_part2);
                tokens = rest;
                lhs = Expr::Mul(lhs.into(), rhs.into())
            }
            _ => break (lhs, tokens),
        }
    }
}

impl Expr {
    pub fn evaluate(&self) -> i64 {
        match self {
            Expr::Term(value) => *value,
            Expr::Add(lhs, rhs) => lhs.evaluate() + rhs.evaluate(),
            Expr::Mul(lhs, rhs) => lhs.evaluate() * rhs.evaluate(),
            Expr::Parens(inner) => inner.evaluate(),
        }
    }
}
