use std::cmp::Ordering::*;
use std::collections::*;

#[derive(Debug, Copy, Clone, PartialEq)]
struct Moon {
    position: [i32; 3],
    velocity: [i32; 3],
}

fn main() {
    let moons = [
        Moon::new([17, -9, 4]),
        Moon::new([2, 2, -13]),
        Moon::new([-1, 5, -1]),
        Moon::new([4, 7, -7]),
    ];

    let cycles = cyclic_steps(moons);

    println!("Time steps: {}", cycles);
}

fn cyclic_steps(mut moons: [Moon; 4]) -> usize {
    #[derive(Debug, Copy, Clone, PartialEq, Eq, Hash)]
    struct State {
        positions: [i32; 4],
        velocities: [i32; 4],
    }

    #[derive(Debug, Copy, Clone)]
    struct Cycle {
        start: usize,
        stride: usize,
    }

    let mut states: [HashMap<State, usize>; 3] = [HashMap::new(), HashMap::new(), HashMap::new()];
    let mut cycles = [None; 3];

    let mut time = 0;

    loop {
        for i in 0..3 {
            let cycle = &mut cycles[i];
            let state = &mut states[i];

            if cycle.is_none() {
                let mut current = State {
                    positions: [0; 4],
                    velocities: [0; 4],
                };

                for m in 0..4 {
                    current.positions[m] = moons[m].position[i];
                    current.velocities[m] = moons[m].velocity[i];
                }

                match state.entry(current) {
                    hash_map::Entry::Occupied(previous) => {
                        let previous = *previous.get();
                        *cycle = Some(Cycle {
                            start: previous,
                            stride: time - previous,
                        });
                    }

                    hash_map::Entry::Vacant(entry) => {
                        entry.insert(time);
                    }
                }
            }
        }

        if cycles.iter().all(|cycle| cycle.is_some()) {
            break lcm(
                cycles[0].unwrap().stride,
                lcm(cycles[1].unwrap().stride, cycles[2].unwrap().stride),
            );
        }

        time += 1;

        moons = time_step(moons);
    }
}

fn time_step(mut moons: [Moon; 4]) -> [Moon; 4] {
    for i in 0..moons.len() {
        for j in 0..moons.len() {
            let delta = moons[i].gravity(moons[j]);
            moons[i].velocity = vec_add(delta, moons[i].velocity);
        }
    }

    for moon in &mut moons {
        moon.position = vec_add(moon.position, moon.velocity);
    }

    moons
}

fn vec_add(a: [i32; 3], b: [i32; 3]) -> [i32; 3] {
    let mut sum = [0; 3];

    for i in 0..3 {
        sum[i] = a[i] + b[i];
    }

    sum
}

fn lcm(a: usize, b: usize) -> usize {
    (a * b) / gcd(a, b)
}

fn gcd(a: usize, b: usize) -> usize {
    let (mut a, mut b) = if a < b { (b, a) } else { (a, b) };

    while b != 0 {
        let tmp = b;
        b = a % b;
        a = tmp;
    }

    a
}

impl Moon {
    pub fn new(position: [i32; 3]) -> Moon {
        Moon {
            position,
            velocity: [0; 3],
        }
    }

    pub fn gravity(self, other: Moon) -> [i32; 3] {
        let mut delta = [0; 3];

        for i in 0..3 {
            delta[i] = match self.position[i].cmp(&other.position[i]) {
                Equal => 0,
                Less => 1,
                Greater => -1,
            }
        }

        delta
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn example_1() {
        let moons = [
            Moon::new([-1, 0, 2]),
            Moon::new([2, -10, -7]),
            Moon::new([4, -8, 8]),
            Moon::new([3, 5, -1]),
        ];

        let cycles = cyclic_steps(moons);

        assert_eq!(cycles, 2772)
    }

    #[test]
    fn example_2() {
        let moons = [
            Moon::new([-8, -10, 0]),
            Moon::new([5, 5, 10]),
            Moon::new([2, -7, 3]),
            Moon::new([9, -8, -3]),
        ];

        let cycles = cyclic_steps(moons);

        assert_eq!(cycles, 4686774924);
    }
}
