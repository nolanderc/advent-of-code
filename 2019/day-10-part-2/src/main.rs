use std::collections::HashSet;
use std::f32::consts::PI;
use std::fs;
use std::path::Path;

fn main() {
    let points = load_input("input");

    let center = most_visible(&points);
    let last = vapor_order(center, points).nth(200 - 1).unwrap();

    println!("200th: {:?}", last);
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

fn most_visible(points: &[Point]) -> Point {
    points
        .iter()
        .copied()
        .max_by_key(|&origin| visible(origin, points.iter().copied()).count())
        .unwrap()
}

fn vapor_order(center: Point, points: Vec<Point>) -> impl Iterator<Item = Point> {
    let mut points = points.into_iter().collect::<HashSet<_>>();

    points.remove(&center);

    let mut order = Vec::new();

    while !points.is_empty() {
        dbg!(points.len());

        let mut visible = visible(center, points.iter().copied()).collect::<Vec<_>>();
        dbg!(&visible);

        visible.sort_by_key(|&point| {
            let angle = center.angle(point);
            Ordered(angle)
        });

        for point in &visible {
            points.remove(point);
        }

        order.append(&mut visible);
    }

    order.into_iter()
}

#[derive(Debug, Copy, Clone, PartialEq, PartialOrd)]
struct Ordered(f32);

impl Eq for Ordered {}

impl Ord for Ordered {
    fn cmp(&self, other: &Self) -> std::cmp::Ordering {
        self.0.partial_cmp(&other.0).unwrap()
    }
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

    pub fn angle(self, other: Point) -> f32 {
        let dx = (other.x - self.x) as f32;
        let dy = (other.y - self.y) as f32;

        let angle = f32::atan2(dx, -dy);

        if angle < 0.0 {
            2.0 * PI + angle
        } else {
            angle
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn example_large() {
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

        let points = parse_input(map);
        let center = most_visible(&points);

        let order = vapor_order(center, points).collect::<Vec<_>>();
        let pos = order.iter().position(|p| p.x == 8 && p.y == 2);
        let last = *order.iter().nth(199).unwrap();

        assert_eq!(last, Point { x: 8, y: 2 });
    }
}
