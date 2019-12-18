use std::collections::HashSet;
use std::fs;
use std::path::Path;

fn main() {
    let points = load_input("input");

    let visible = points
        .iter()
        .copied()
        .map(|origin| visible(origin, points.iter().copied()))
        .map(|visible| visible.count())
        .max()
        .unwrap();

    println!("Maximum visible: {}", visible);
}

#[derive(Debug, Copy, Clone, PartialEq, Eq, Hash)]
struct Point {
    x: i32,
    y: i32,
}

fn load_input(path: impl AsRef<Path>) -> Vec<Point> {
    let input = fs::read_to_string(path).unwrap();
    parse_input(&input)
}

fn parse_input(map: &str) -> Vec<Point> {
    let mut points = Vec::new();

    for (y, line) in map.trim().lines().enumerate() {
        for (x, ch) in line.chars().enumerate() {
            match ch {
                '#' => points.push(Point {
                    x: x as i32,
                    y: y as i32,
                }),
                '.' => (),
                _ => unreachable!("invalid map character: {:?}", ch),
            }
        }
    }

    points
}

fn visible(
    origin: Point,
    points: impl Iterator<Item = Point> + Clone,
) -> impl Iterator<Item = Point> {
    let points = points.filter(|p| *p != origin).collect::<Vec<_>>();

    let mut candidate = points.iter().copied().collect::<HashSet<_>>();

    'a: for &a in &points {
        'b: for &b in &points {
            if a == b {
                continue 'b;
            }

            if Point::colinear(origin, a, b) {

                let a_dist = origin.distance2(a);
                let b_dist = origin.distance2(b);
                if a_dist < b_dist {
                    candidate.remove(&b);
                    continue 'b;
                } else if b_dist < a_dist {
                    candidate.remove(&a);
                    continue 'a;
                }
            }
        }
    }

    candidate.into_iter()
}

fn most_visible(map: &str) -> (Point, usize) {
    let points = parse_input(map);
    points
        .iter()
        .copied()
        .map(|origin| (origin, visible(origin, points.iter().copied()).count()))
        .max_by_key(|(_, visible)| *visible)
        .unwrap()
}

impl Point {
    pub fn colinear(self, a: Point, b: Point) -> bool {
        let a_dir = Point {
            x: a.x - self.x,
            y: a.y - self.y,
        };
        let b_dir = Point {
            x: b.x - self.x,
            y: b.y - self.y,
        };

        let det = a_dir.x * b_dir.y - a_dir.y * b_dir.x;
        let dot = a_dir.x * b_dir.x + a_dir.y * b_dir.y;

        dot > 0 && det == 0
    }

    pub fn distance2(self, other: Point) -> i32 {
        let dx = self.x - other.x;
        let dy = self.y - other.y;
        dx * dx + dy * dy
    }
}

#[test]
fn example1() {
    let map = "......#.#.\n\
               #..#.#....\n\
               ..#######.\n\
               .#.#.###..\n\
               .#..#.....\n\
               ..#....#.#\n\
               #..#....#.\n\
               .##.#..###\n\
               ##...#..#.\n\
               .#....####";

    let (point, count) = most_visible(map);

    assert_eq!(count, 33);
    assert_eq!(point, Point { x: 5, y: 8 });
}

#[test]
fn example2() {
    let map = "#.#...#.#.\n\
               .###....#.\n\
               .#....#...\n\
               ##.#.#.#.#\n\
               ....#.#.#.\n\
               .##..###.#\n\
               ..#...##..\n\
               ..##....##\n\
               ......#...\n\
               .####.###.";

    let (point, count) = most_visible(map);

    assert_eq!(count, 35);
    assert_eq!(point, Point { x: 1, y: 2 });
}

#[test]
fn example3() {
    let map = ".#..#..###\n\
               ####.###.#\n\
               ....###.#.\n\
               ..###.##.#\n\
               ##.##.#.#.\n\
               ....###..#\n\
               ..#.#..#.#\n\
               #..#.#.###\n\
               .##...##.#\n\
               .....#.#..";

    let (point, count) = most_visible(map);

    assert_eq!(count, 41);
    assert_eq!(point, Point { x: 6, y: 3 });
}

#[test]
fn example4() {
    let map = ".#..##.###...#######\n\
               ##.############..##.\n\
               .#.######.########.#\n\
               .###.#######.####.#.\n\
               #####.##.#.##.###.##\n\
               ..#####..#.#########\n\
               ####################\n\
               #.####....###.#.#.##\n\
               ##.#################\n\
               #####.##.###..####..\n\
               ..######..##.#######\n\
               ####.##.####...##..#\n\
               .#####..#.######.###\n\
               ##...#.##########...\n\
               #.##########.#######\n\
               .####.#.###.###.#.##\n\
               ....##.##.###..#####\n\
               .#.#.###########.###\n\
               #.#.#.#####.####.###\n\
               ###.##.####.##.#..##";

    let (point, count) = most_visible(map);

    assert_eq!(count, 210);
    assert_eq!(point, Point { x: 11, y: 13 });
}

