use std::collections::*;
use std::fs;

#[derive(Debug, Clone)]
struct Map {
    rows: Vec<Vec<Tile>>,
    keys: usize,
    width: usize,
    height: usize,
}

#[derive(Debug, Copy, Clone, PartialEq, Eq, Hash)]
struct Point {
    x: usize,
    y: usize,
}

#[derive(Debug, Copy, Clone, PartialEq, Eq)]
enum Tile {
    Start,
    Wall,
    Open,
    Door(Keyhole),
    Key(Keyhole),
}

#[derive(Debug, Copy, Clone, PartialEq, Eq)]
struct Keyhole(char);

fn main() {
    let map = load_map();
    let path = shortest_path(&map).unwrap();

    println!("Shortest path: {}", path);
}

fn load_map() -> Map {
    let text = fs::read_to_string("input").unwrap();
    parse_map(&text)
}

fn parse_map(text: &str) -> Map {
    let mut map = Map {
        rows: Vec::new(),
        keys: 0,
        width: 0,
        height: 0,
    };
    for line in text.trim().lines() {
        let mut row = Vec::new();
        for ch in line.trim().chars() {
            let tile = match ch {
                '@' => Tile::Start,
                '#' => Tile::Wall,
                '.' => Tile::Open,
                'A'..='Z' => Tile::Door(Keyhole(ch.to_ascii_lowercase())),
                'a'..='z' => {
                    map.keys += 1;
                    Tile::Key(Keyhole(ch))
                }
                _ => panic!("Invalid character: {}", ch),
            };

            row.push(tile);
        }

        map.rows.push(row);
    }

    map.width = map.rows[0].len();
    map.height = map.rows.len();

    map
}

fn shortest_path(map: &Map) -> Option<usize> {
    let starts = map
        .iter()
        .filter(|(_, tile)| tile == &Tile::Start)
        .map(|(pos, _)| pos)
        .collect::<Vec<_>>();

    let keys = 0u32;
    let mut memo = HashMap::new();

    let mut start = [Point { x: 0, y: 0 }; 4];
    start.clone_from_slice(&starts[0..4]);

    shortest_path_rec(map, start, keys, &mut memo)
}

fn shortest_path_rec(
    map: &Map,
    start: [Point; 4],
    keys: u32,
    memo: &mut HashMap<([Point; 4], u32), Option<usize>>,
) -> Option<usize> {
    if let Some(previous) = memo.get(&(start, keys)) {
        *previous
    } else if keys.count_ones() as usize == map.keys {
        Some(0)
    } else {
        let best = (0..4)
            .filter_map(|i| {
                map.reachable_keys(start[i], keys)
                    .into_iter()
                    .filter_map(|(point, distance, key)| {
                        let mut next = start;
                        next[i] = point;
                        let keys = keys | key.mask();
                        shortest_path_rec(map, next, keys, memo).map(move |d| distance + d)
                    })
                    .min()
            })
            .min();

        memo.insert((start, keys), best);

        best
    }
}

impl Map {
    pub fn iter<'a>(&'a self) -> impl Iterator<Item = (Point, Tile)> + 'a {
        self.rows.iter().enumerate().flat_map(|(y, row)| {
            row.iter()
                .enumerate()
                .map(move |(x, tile)| (Point { x, y }, *tile))
        })
    }

    pub fn reachable_keys(&self, source: Point, keys: u32) -> Vec<(Point, usize, Keyhole)> {
        let mut reachable = Vec::new();
        let mut queue = VecDeque::from(vec![(source, 0)]);
        let mut visited = vec![vec![false; self.width]; self.height];

        while let Some((Point { x, y }, distance)) = queue.pop_front() {
            if !visited[y][x] {
                visited[y][x] = true;
                let neighbours = [
                    Point { x: x - 1, y },
                    Point { x: x + 1, y },
                    Point { x, y: y - 1 },
                    Point { x, y: y + 1 },
                ];

                for &new in &neighbours {
                    if visited[new.y][new.x] {
                        continue;
                    }

                    let new_distance = distance + 1;

                    let traversable = match self.rows[new.y][new.x] {
                        Tile::Open | Tile::Start => true,
                        Tile::Door(hole) if keys & hole.mask() != 0 => true,
                        Tile::Key(hole) => {
                            if keys & hole.mask() == 0 {
                                reachable.push((new, new_distance, hole));
                            }
                            true
                        }
                        _ => false,
                    };

                    if traversable {
                        queue.push_back((new, new_distance));
                    }
                }
            }
        }

        reachable
    }
}

impl Keyhole {
    pub fn mask(self) -> u32 {
        1 << (self.0 as u8 - b'a')
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use indoc::indoc;

    #[test]
    fn example_1() {
        let text = indoc!(
            "
            #############
            #DcBa.#.GhKl#
            #.###@#@#I###
            #e#d#####j#k#
            ###C#@#@###J#
            #fEbA.#.FgHi#
            #############
            "
        );
        let map = parse_map(text);
        let path = shortest_path(&map).unwrap();
        assert_eq!(path, 32);
    }

    #[test]
    fn example_2() {
        let text = indoc!(
            "
            #############
            #g#f.D#..h#l#
            #F###e#E###.#
            #dCba@#@BcIJ#
            #############
            #nK.L@#@G...#
            #M###N#H###.#
            #o#m..#i#jk.#
            #############
            "
        );
        let map = parse_map(text);
        let path = shortest_path(&map).unwrap();
        assert_eq!(path, 72);
    }
}
