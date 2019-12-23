use std::collections::*;
use std::fs;
use std::path::Path;

#[derive(Debug, Copy, Clone, PartialEq, Eq, Hash)]
struct Point {
    x: usize,
    y: usize,
}

#[derive(Debug, Copy, Clone, PartialEq, Eq, Hash)]
enum Edge {
    Inner,
    Outer,
    Tile,
}

struct Map {
    start: Point,
    end: Point,
    edges: HashMap<Point, Vec<(Point, Edge)>>,
}

fn main() {
    let map = load_input("input");
    let distance = map.distance().unwrap();
    println!("Steps: {}", distance);
}

fn load_input(path: impl AsRef<Path>) -> Map {
    let text = fs::read_to_string(path).unwrap();
    parse_input(&text)
}

fn parse_input(text: &str) -> Map {
    let lines = text
        .lines()
        .map(|line| line.chars().collect::<Vec<_>>())
        .take_while(|line| !line.is_empty())
        .collect::<Vec<_>>();

    let height = lines.len();
    let width = lines.iter().map(|line| line.len()).max().unwrap();

    let mut labels = HashMap::new();

    for y in 0..height {
        let line = &lines[y];
        for x in 0..line.len() {
            if lines[y][x].is_alphabetic() {
                let horizontal = lines[y].get(x + 1).filter(|a| a.is_alphabetic()).is_some();
                let vertical = lines
                    .get(y + 1)
                    .map(|line| line.get(x))
                    .flatten()
                    .filter(|a| a.is_alphabetic())
                    .is_some();

                let is_maze = |ch: char| ch == '#' || ch == '.';

                let (other, (dx, dy)) = if horizontal {
                    let sample = *lines[y].get(x + 2).unwrap_or(&' ');
                    let dx = if is_maze(sample) { 2 } else { -1 };

                    (lines[y][x + 1], (dx, 0))
                } else if vertical {
                    let sample = *lines.get(y + 2).map(|l| l.get(x)).flatten().unwrap_or(&' ');
                    let dy = if is_maze(sample) { 2 } else { -1 };
                    (lines[y + 1][x], (0, dy))
                } else {
                    continue;
                };

                let label = [lines[y][x], other];
                let exit = Point {
                    x: (x as isize + dx) as usize,
                    y: (y as isize + dy) as usize,
                };

                labels.entry(label).or_insert_with(Vec::new).push(exit)
            }
        }
    }

    let labels = labels;
    let portals = labels
        .iter()
        .flat_map(|(label, point)| point.iter().copied().map(move |p| (p, *label)))
        .collect::<HashMap<_, _>>();

    let mut open = HashSet::new();
    for y in 0..height {
        for x in 0..width {
            if lines[y][x] == '.' {
                open.insert(Point { x, y });
            }
        }
    }

    let mut edges = HashMap::new();
    for &point in &open {
        let adjacent = edges.entry(point).or_insert_with(Vec::new);

        let Point { x, y } = point;

        let neighbour = [
            Point { x: x + 1, y },
            Point { x: x - 1, y },
            Point { x, y: y + 1 },
            Point { x, y: y - 1 },
        ];

        for n in &neighbour {
            if open.contains(n) {
                adjacent.push((*n, Edge::Tile))
            }
        }

        if let Some(label) = portals.get(&point) {
            if let Some(exit) = labels[label].iter().find(|&&e| e != point) {
                let is_outer =
                    point.x < 3 || point.y < 3 || point.x >= width - 3 || point.y >= height - 3;
                let edge = match is_outer {
                    true => Edge::Outer,
                    false => Edge::Inner,
                };
                adjacent.push((*exit, edge));
            }
        }
    }

    let start = labels[&['A', 'A']][0];
    let end = labels[&['Z', 'Z']][0];

    Map { start, end, edges }
}

impl Map {
    pub fn distance(&self) -> Option<usize> {
        let mut queue = VecDeque::new();
        let mut visited = HashSet::new();

        queue.push_back(((self.start, 0), 0));

        while let Some((node, distance)) = queue.pop_front() {
            if visited.insert(node) {
                let (point, level) = node;

                if node == (self.end, 0) {
                    return Some(distance);
                }

                for &(n, edge) in &self.edges[&point] {
                    let new_level = match edge {
                        Edge::Tile => level,
                        Edge::Outer if level == 0 => continue,
                        Edge::Outer => level - 1,
                        Edge::Inner => level + 1,
                    };

                    queue.push_back(((n, new_level), distance + 1))
                }
            }
        }

        None
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn example_1() {
        let map = load_input("example_1");
        assert_eq!(map.distance(), Some(26));
    }

    #[test]
    fn example_2() {
        let map = load_input("example_2");
        assert_eq!(map.distance(), Some(396));
    }
}
