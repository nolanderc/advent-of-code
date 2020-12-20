use std::collections::{HashMap, HashSet};
use std::io::Read;

fn main() {
    let mut input = String::new();
    std::io::stdin().read_to_string(&mut input).unwrap();

    let mut lines = input.trim().lines().map(|line| line.trim());

    let mut images = Vec::new();

    while let Some(header) = lines.next() {
        let id = header
            .strip_prefix("Tile ")
            .unwrap()
            .strip_suffix(":")
            .unwrap()
            .parse::<u32>()
            .unwrap();

        let mut pixels = [0; 10];
        let rows = lines.by_ref().take_while(|line| !line.is_empty());
        for (i, row) in rows.enumerate() {
            let mut pixel_row = 0;
            for col in row.chars() {
                pixel_row <<= 1;
                pixel_row |= match col {
                    '#' => 1,
                    '.' => 0,
                    _ => panic!(),
                };
            }
            pixels[i] = pixel_row;
        }

        images.push(Image { id, pixels })
    }

    println!("{}", part1(&images));
}

fn part1(images: &[Image]) -> u64 {
    let mut borders = HashMap::new();

    #[derive(Debug, Copy, Clone, PartialEq, Eq, Hash)]
    struct Border {
        image: u32,
        side: Side,
        reversed: bool,
    }

    const SIDES: [Side; 4] = [Side::North, Side::South, Side::West, Side::East];

    for image in images {
        for &side in SIDES.iter() {
            let border = image.border(side);
            for reversed in (0..=1).map(|r| r != 0) {
                let border = if reversed {
                    reversed_bits(border)
                } else {
                    border
                };

                borders.entry(border).or_insert_with(Vec::new).push(Border {
                    image: image.id,
                    side,
                    reversed,
                });
            }
        }
    }

    // In the input: for a given side, at most one other image can be placed adjacent to it.
    for ids in borders.values() {
        assert!(matches!(ids.len(), 1 | 2));
    }

    // For each image, the images that can be adjacent to its edges
    let mut adjacent = HashMap::new();
    for ids in borders.values() {
        for this in ids.iter() {
            for other in ids.iter().filter(|b| b.image != this.image) {
                adjacent.entry(this.image).or_insert_with(Vec::new).push(other);
            }
        }
    }

    let mut corners = Vec::with_capacity(4);
    for (this, others) in adjacent.iter() {
        if others.len() == 4 {
            corners.push(*this);
            dbg!((this, others));
        }
    }

    if corners.len() == 4 {
        corners.iter().map(|c| *c as u64).product()
    } else {
        panic!("could not cheat our way to four corners")
    }
}

fn isqrt(x: usize) -> usize {
    f64::sqrt(x as f64).floor() as usize
}

fn reversed_bits(mut x: u16) -> u16 {
    let mut res = 0;
    for _ in 0..10 {
        res <<= 1;
        res |= x & 1;
        x >>= 1;
    }
    res
}

#[derive(Debug, Copy, Clone)]
struct Image {
    pixels: [u16; 10],
    id: u32,
}

#[derive(Debug, Copy, Clone, PartialEq, Eq, Hash)]
enum Side {
    North,
    South,
    West,
    East,
}

impl Image {
    fn border(&self, side: Side) -> u16 {
        match side {
            Side::North => self.pixels[0],
            Side::South => self.pixels[9],
            Side::West => self.column(0),
            Side::East => self.column(9),
        }
    }

    fn column(self, col: usize) -> u16 {
        self.pixels
            .iter()
            .fold(0, |res, row| res << 1 | (row >> (9 - col)) & 1)
    }

    fn rotated(self) -> Self {
        let mut new = self;
        for i in 0..10 {
            new.pixels[i] = self.column(9 - i);
        }
        new
    }

    fn flipped(mut self) -> Self {
        for i in 0..5 {
            self.pixels.swap(i, 9 - i);
        }
        self
    }
}

impl std::fmt::Display for Image {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        for row in self.pixels.iter() {
            let mut mask = 1 << 9;
            while mask > 0 {
                if row & mask == 0 {
                    write!(f, ".")?;
                } else {
                    write!(f, "#")?;
                }
                mask >>= 1;
            }
            writeln!(f)?;
        }

        Ok(())
    }
}
