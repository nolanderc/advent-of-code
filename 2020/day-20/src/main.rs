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

        images.push(Image { id, pixels });
    }

    let joined = join_images(&images);

    println!("{}", part1(&joined));
    println!("{}", part2(&joined));
}

fn part1(joined: &Vec<Vec<Image>>) -> u64 {
    let l = joined.len() - 1;

    let a = joined[0][0].id as u64;
    let b = joined[0][l].id as u64;
    let c = joined[l][0].id as u64;
    let d = joined[l][l].id as u64;

    a * b * c * d
}

fn part2(joined: &Vec<Vec<Image>>) -> u64 {
    let size = joined.len() * 8;
    let mut full = vec![vec![false; size]; size];

    for iy in 0..joined.len() {
        for ix in 0..joined.len() {
            for y in 0..8 {
                for x in 0..8 {
                    full[iy * 8 + y][ix * 8 + x] = joined[iy][ix].get(1 + y, 1 + x);
                }
            }
        }
    }

    let monster = [
        b"                  # ",
        b"#    ##    ##    ###",
        b" #  #  #  #  #  #   ",
    ];

    let mut pattern = Vec::new();
    for y in 0..monster.len() {
        for x in 0..monster[0].len() {
            if monster[y][x] == b'#' {
                pattern.push((x, y));
            }
        }
    }

    let mut images = vec![full.clone(), fliph(full.clone()), flipv(full.clone())];

    for _ in 0..3 {
        for i in images.len() - 3..images.len() {
            images.push(rotate(&images[i]));
        }
    }

    for image in images {
        let matches = pattern_match(&image, &pattern);
        if matches.len() > 0 {
            let mut points = HashSet::new();
            for (x, y) in matches {
                for &(dx, dy) in pattern.iter() {
                    points.insert((x + dx, y + dy));
                }
            }

            let active = image
                .into_iter()
                .map(|row| row.into_iter().filter(|pixel| *pixel).count())
                .sum::<usize>();
            return active as u64 - points.len() as u64;
        }
    }

    panic!()
}

fn pattern_match(image: &Vec<Vec<bool>>, pattern: &Vec<(usize, usize)>) -> Vec<(usize, usize)> {
    let width = pattern.iter().map(|p| p.0).max().unwrap();
    let height = pattern.iter().map(|p| p.1).max().unwrap();

    let mut matches = Vec::new();

    for y in 0..image.len().saturating_sub(height) {
        'offset: for x in 0..image[0].len().saturating_sub(width) {
            for &(dx, dy) in pattern.iter() {
                if !image[y + dy][x + dx] {
                    continue 'offset;
                }
            }

            matches.push((x, y));
        }
    }

    matches
}

fn rotate(image: &Vec<Vec<bool>>) -> Vec<Vec<bool>> {
    let size = image.len();
    let mut new = vec![vec![false; size]; size];

    for y in 0..size {
        for x in 0..size {
            new[y][x] = image[size - 1 - x][y];
        }
    }

    new
}

fn flipv(mut image: Vec<Vec<bool>>) -> Vec<Vec<bool>> {
    let size = image.len();
    for i in 0..size / 2 {
        image.swap(i, size - 1 - i);
    }
    image
}

fn fliph(mut image: Vec<Vec<bool>>) -> Vec<Vec<bool>> {
    let size = image.len();
    for row in image.iter_mut() {
        for i in 0..size / 2 {
            row.swap(i, size - 1 - i);
        }
    }
    image
}

fn join_images(images: &[Image]) -> Vec<Vec<Image>> {
    let mut borders = HashMap::new();

    let mut add_border = |border, image, side, reversed| {
        borders
            .entry(border)
            .or_insert_with(Vec::new)
            .push((image, side, reversed));
    };

    for &image in images.iter() {
        for &side in SIDES.iter() {
            let border = image.border(side);
            let reversed = reversed_bits(border);

            add_border(border, image, side, false);
            add_border(reversed, image, side, true);
        }
    }

    // In the input: no border matches between more than 2 images
    for ids in borders.values() {
        assert!(matches!(ids.len(), 1 | 2));
    }

    borders.retain(|_, ids| ids.len() == 2);
    borders.shrink_to_fit();

    // pick an arbitrary image and place it into the grid.
    let side = isqrt(images.len()) as i32;
    let mut grid = HashMap::new();

    let first = *images.first().unwrap();
    grid.insert((side, side), first);

    complete_grid(&mut grid, &borders, (side, side));

    let (mut x_min, mut x_max) = (side, side);
    let (mut y_min, mut y_max) = (side, side);
    for &(x, y) in grid.keys() {
        x_min = x.min(x_min);
        x_max = x.max(x_max);
        y_min = y.min(y_min);
        y_max = y.max(y_max);
    }

    // we assume this from the input data
    assert_eq!(1 + x_max - x_min, side);
    assert_eq!(1 + y_max - y_min, side);

    let mut joined = Vec::with_capacity(side as usize);
    for y in y_min..=y_max {
        let mut row = Vec::with_capacity(side as usize);
        for x in x_min..=x_max {
            row.push(grid[&(x, y)]);
        }
        joined.push(row);
    }

    joined
}

fn complete_grid(
    grid: &mut HashMap<(i32, i32), Image>,
    borders: &HashMap<u16, Vec<(Image, Side, bool)>>,
    current: (i32, i32),
) {
    let image = grid[&current];
    for &direction in SIDES.iter() {
        let (dx, dy) = direction.delta();
        let new_pos = (current.0 + dx, current.1 + dy);

        if grid.contains_key(&new_pos) {
            continue;
        }

        let border = image.border(direction);
        match borders.get(&border) {
            None => {}
            Some(candidates) => {
                for &(mut cand, mut side, reversed) in candidates.iter() {
                    if image.id == cand.id {
                        continue;
                    }

                    // +-a-+
                    // b   d
                    // +-c-+

                    while side != direction.opposite() {
                        side = side.rotated();
                        cand = cand.rotated();
                    }

                    if !reversed {
                        cand = match side {
                            Side::North | Side::South => cand.flipped_horiz(),
                            Side::West | Side::East => cand.flipped_vert(),
                        }
                    }

                    if is_valid(grid, new_pos, cand) {
                        grid.insert(new_pos, cand);
                        complete_grid(grid, borders, new_pos);
                    }
                }
            }
        }
    }
}

fn is_valid(grid: &HashMap<(i32, i32), Image>, pos: (i32, i32), image: Image) -> bool {
    for &side in SIDES.iter() {
        let (dx, dy) = side.delta();
        let new_pos = (pos.0 + dx, pos.1 + dy);

        if let Some(adjacent) = grid.get(&new_pos) {
            if reversed_bits(image.border(side)) != adjacent.border(side.opposite()) {
                return false;
            }
        }
    }

    true
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

#[derive(Debug, Copy, Clone, PartialEq, Eq, Hash)]
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

const SIDES: [Side; 4] = [Side::North, Side::South, Side::West, Side::East];

impl Side {
    fn rotated(self) -> Self {
        match self {
            Side::North => Side::West,
            Side::South => Side::East,
            Side::West => Side::South,
            Side::East => Side::North,
        }
    }

    fn delta(self) -> (i32, i32) {
        match self {
            Side::North => (0, -1),
            Side::South => (0, 1),
            Side::West => (-1, 0),
            Side::East => (1, 0),
        }
    }

    fn opposite(self) -> Side {
        match self {
            Side::North => Side::South,
            Side::South => Side::North,
            Side::West => Side::East,
            Side::East => Side::West,
        }
    }
}

impl Image {
    fn border(&self, side: Side) -> u16 {
        match side {
            Side::North => self.pixels[0],
            Side::South => reversed_bits(self.pixels[9]),
            Side::West => reversed_bits(self.column(0)),
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

    fn flipped_vert(mut self) -> Self {
        for i in 0..5 {
            self.pixels.swap(i, 9 - i);
        }
        self
    }

    fn flipped_horiz(mut self) -> Self {
        for row in self.pixels.iter_mut() {
            *row = reversed_bits(*row);
        }
        self
    }

    fn get(&self, row: usize, col: usize) -> bool {
        self.pixels[row] >> (9 - col) & 1 != 0
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
