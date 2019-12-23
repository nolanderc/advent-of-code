use intcode::*;
use std::sync::mpsc::channel;
use std::thread;

#[derive(Debug, Copy, Clone)]
struct Frame {
    target: usize,
    packet: Packet,
}

#[derive(Debug, Copy, Clone)]
struct Packet {
    x: i64,
    y: i64,
}

fn main() {
    let mut inputs = Vec::new();

    let (network, packets) = channel::<Frame>();

    for address in 0..50 {
        let (sender, receiver) = channel::<Packet>();
        inputs.push(sender);

        let mut computer = Computer::load("input").unwrap();
        computer.provide_input(Some(address));

        let network = network.clone();
        thread::spawn(move || loop {
            match computer.run() {
                Action::Halt => break,
                Action::NeedsInput => match receiver.try_recv() {
                    Ok(packet) => computer.provide_input(vec![packet.x, packet.y]),
                    Err(_) => computer.provide_input(Some(-1)),
                },
                Action::Output(target) => {
                    let x = computer.run().output();
                    let y = computer.run().output();
                    network.send(Frame {
                        target: target as usize,
                        packet: Packet { x, y },
                    }).unwrap();
                }
            }
        });
    }

    while let Ok(frame) = packets.recv() {
        let packet = frame.packet;

        if frame.target == 255 {
            println!("Got Y: {}", packet.y);
            break;
        }

        inputs[frame.target].send(packet).unwrap();
    }

    println!("Done.");
}
