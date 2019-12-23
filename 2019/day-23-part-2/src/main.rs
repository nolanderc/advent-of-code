use intcode::*;
use std::collections::*;

#[derive(Debug, Copy, Clone, PartialEq, Eq)]
struct Packet {
    x: i64,
    y: i64,
}

fn main() {
    let mut computers = (0..50)
        .map(|address| {
            let mut computer = Computer::load("input").unwrap();
            computer.provide_input(Some(address));
            computer
        })
        .collect::<Vec<_>>();

    let mut queues = vec![VecDeque::<Packet>::new(); 50];
    let mut nat = None;
    let mut previous = None;

    loop {
        let mut idle = true;
        for (i, computer) in computers.iter_mut().enumerate() {
            let mut waiting = false;
            loop {
                match computer.run() {
                    Action::Halt => break,
                    Action::NeedsInput => match queues[i].pop_front() {
                        Some(packet) => {
                            idle = false;
                            computer.provide_input(vec![packet.x, packet.y]);
                        }
                        None => {
                            computer.provide_input(Some(-1));
                            if waiting {
                                break;
                            }
                            waiting = true;
                        }
                    },
                    Action::Output(target) => {
                        idle = false;
                        let x = computer.run().output();
                        let y = computer.run().output();
                        let packet = Packet { x, y };
                        if target == 255 {
                            nat = Some(packet);
                        } else {
                            queues[target as usize].push_back(packet);
                        }
                    }
                }
            }
        }

        if idle && queues.iter().all(|queue| queue.is_empty()) {
            queues[0].push_back(nat.expect("NAT had no packet"));
            if nat == previous {
                println!("Got NAT: {}", nat.unwrap().y);
                break;
            }
            previous = nat;
        }
    }

    println!("Done.");
}
