use std::cmp::Ordering::*;

#[derive(Debug, Copy, Clone, PartialEq)]
struct Moon {
    position: [i32; 3],
    velocity: [i32; 3],
}

fn main() {
    let moons = vec![
        Moon::new([17, -9, 4]),
        Moon::new([2, 2, -13]),
        Moon::new([-1, 5, -1]),
        Moon::new([4, 7, -7]),
    ];

    let moons = step_time(moons, 1000);
    let energy = total_energy(&moons);
    println!("Energy: {}", energy);
}

fn step_time(mut moons: Vec<Moon>, steps: usize) -> Vec<Moon> {
    for _ in 0..steps {
        for i in 0..moons.len() {
            for j in 0..moons.len() {
                let delta = moons[i].gravity(moons[j]);
                moons[i].velocity = vec_add(delta, moons[i].velocity);
            }
        }

        for moon in &mut moons {
            moon.position = vec_add(moon.position, moon.velocity);
        }
    }

    moons
}

fn total_energy(moons: &[Moon]) -> i32 {
    moons
        .iter()
        .map(|moon| {
            let potential = moon.position.iter().map(|p| p.abs()).sum::<i32>();
            let kinetic = moon.velocity.iter().map(|p| p.abs()).sum::<i32>();
            potential * kinetic
        })
        .sum()
}

fn vec_add(a: [i32; 3], b: [i32; 3]) -> [i32; 3] {
    let mut sum = [0; 3];

    for i in 0..3 {
        sum[i] = a[i] + b[i];
    }

    sum
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
        let moons = vec![
            Moon::new([-1, 0, 2]),
            Moon::new([2, -10, -7]),
            Moon::new([4, -8, 8]),
            Moon::new([3, 5, -1]),
        ];

        let moons = step_time(moons, 10);
        let energy = total_energy(&moons);

        assert_eq!(energy, 179)
    }
}
