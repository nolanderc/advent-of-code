use intcode::*;
use std::collections::*;
use std::fs;

#[derive(Debug, Copy, Clone, PartialEq, Eq, Hash)]
struct Point {
    x: i64,
    y: i64,
}

#[derive(Debug, Copy, Clone, PartialEq, Eq)]
enum Tile {
    Empty,
    Wall,
    Block,
    Horizontal,
    Ball,
}

fn main() {
    let code = load_code();
    let arcade = Computer::new(code);

    let mut grid = HashMap::new();

    let (_input, mut output) = arcade.run_async();

    let mut next_command = move || -> Option<(Point, Tile)> {
        let x = output.recv().ok()?;
        let y = output.recv().ok()?;
        let t = output.recv().ok()?;

        let tile = match t {
            0 => Tile::Empty,
            1 => Tile::Wall,
            2 => Tile::Block,
            3 => Tile::Horizontal,
            4 => Tile::Ball,
            _ => unreachable!(),
        };

        Some((Point { x, y }, tile))
    };

    while let Some((point, tile)) = next_command() {
        grid.insert(point, tile);
    }

    let blocks = grid.values().filter(|&&t| t == Tile::Block).count();
    println!("{}", blocks)
}

fn load_code() -> Vec<i64> {
    let text = fs::read_to_string("input").unwrap();
    text.lines()
        .next()
        .unwrap()
        .split(',')
        .map(|w| w.parse().unwrap())
        .collect()
}
