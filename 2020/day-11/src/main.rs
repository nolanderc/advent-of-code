use std::io::Read;

fn main() {
    let mut input = String::new();
    std::io::stdin().read_to_string(&mut input).unwrap();

    let seats = input
        .lines()
        .map(|line| line.trim().as_bytes().to_vec())
        .collect::<Vec<_>>();

    println!("{}", find_equilibrium(seats.clone(), part1));
    println!("{}", find_equilibrium(seats, part2));
}

fn find_equilibrium(mut seats: Seats, next: impl Fn(&Seats) -> Seats) -> u32 {
    loop {
        let new = next(&seats);
        if new == seats {
            break;
        }
        seats = new;
    }

    let mut occupied = 0;
    for row in seats.iter() {
        for &seat in row.iter() {
            occupied += (seat == b'#') as u32;
        }
    }
    occupied
}

type Seats = Vec<Vec<u8>>;

fn part1(seats: &Seats) -> Seats {
    let rows = seats.len();
    let cols = seats[0].len();

    let mut new = vec![vec![b'.'; cols]; rows];

    for row in 0..rows {
        for col in 0..cols {
            let mut adjacent = 0;

            for dx in -1..=1 {
                for dy in -1..=1 {
                    let y = row as isize + dy;
                    let x = col as isize + dx;

                    if dx == 0 && dy == 0 {
                        continue;
                    }

                    if x < 0 || x as usize >= cols || y < 0 || y as usize >= rows {
                        continue;
                    }

                    if seats[y as usize][x as usize] == b'#' {
                        adjacent += 1;
                    }
                }
            }

            match seats[row][col] {
                b'L' if adjacent == 0 => new[row][col] = b'#',
                b'#' if adjacent >= 4 => new[row][col] = b'L',
                seat => new[row][col] = seat,
            }
        }
    }

    new
}

fn part2(seats: &Seats) -> Seats {
    let rows = seats.len();
    let cols = seats[0].len();

    let mut new = vec![vec![b'.'; cols]; rows];

    for row in 0..rows {
        for col in 0..cols {
            let mut adjacent = 0;

            for dx in -1..=1 {
                for dy in -1..=1 {
                    if dx == 0 && dy == 0 {
                        continue;
                    }

                    for i in 1.. {
                        let y = row as isize + i * dy;
                        let x = col as isize + i * dx;

                        if x < 0 || x as usize >= cols || y < 0 || y as usize >= rows {
                            break;
                        }

                        let seat = seats[y as usize][x as usize];
                        adjacent += (seat == b'#') as usize;

                        if seat == b'.' {
                            continue;
                        } else {
                            break;
                        }
                    }
                }
            }

            match seats[row][col] {
                b'L' if adjacent == 0 => new[row][col] = b'#',
                b'#' if adjacent >= 5 => new[row][col] = b'L',
                seat => new[row][col] = seat,
            }
        }
    }

    new
}
