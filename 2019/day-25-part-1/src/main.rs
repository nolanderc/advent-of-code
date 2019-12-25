use intcode::*;
use std::fs;
use std::io::{self, BufRead, Write};
use std::mem;
use std::path::PathBuf;
use structopt::*;

#[derive(Debug, StructOpt)]
struct Options {
    #[structopt(short, long)]
    fast_forward: Option<PathBuf>,
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
enum Command {
    Rewind,
    Weight(String),
}

fn main() {
    let options = Options::from_args();

    let mut computer = Computer::load("input").unwrap();

    let mut transcript = String::new();
    let mut prompt = Vec::new();

    let stdin = io::stdin();

    let mut lines: Box<dyn Iterator<Item = String>> = Box::new(None.into_iter());

    if let Some(path) = options.fast_forward {
        let file = fs::read_to_string(&path).unwrap();
        lines = Box::new(
            lines
                .chain(file.lines().map(|line| line.to_owned()))
                .collect::<Vec<_>>()
                .into_iter(),
        );
    }

    let mut lines = lines.chain(stdin.lock().lines().map(|line| line.unwrap()));

    loop {
        match computer.run() {
            Action::Halt => break,
            Action::NeedsInput => {
                let command: String = lines.next().unwrap();
                prompt.push(command.clone());

                if let Some(command) = parse_command(&command) {
                    match command {
                        Command::Rewind => {
                            prompt.pop();
                            prompt.pop();
                            computer = Computer::load("input").unwrap();
                            for command in &prompt {
                                send_command(&mut computer, &command);
                            }
                        }
                        Command::Weight(command) => {
                            find_weight(&mut computer, &command);
                        }
                    }
                } else {
                    send_command(&mut computer, &command);
                }

                let _ = fs::write("prompt", prompt.join("\n"));
            }
            Action::Output(value) => {
                let ch = value as u8 as char;
                print!("{}", ch);
                io::stdout().lock().flush().unwrap();
                transcript.push(ch);
            }
        }
    }

    println!("Done.");
}

fn send_command(computer: &mut Computer, command: &str) {
    computer.provide_input(command.chars().chain(Some('\n')).map(|ch| ch as u8 as i64));
}

fn parse_command(command: &str) -> Option<Command> {
    let mut words = command.split_whitespace();
    let main = words.next()?;

    match main {
        "rewind" => Some(Command::Rewind),
        "weight" => Some(Command::Weight(words.collect::<Vec<_>>().join(" "))),
        _ => None,
    }
}

fn find_weight(computer: &mut Computer, command: &str) {
    send_command(computer, "inv");

    let transcript = run_until_input(computer).expect("failed to look at inventory");

    if let Some(item_start) = transcript.find("- ") {
        let items = transcript[item_start..]
            .lines()
            .take_while(|line| line.starts_with("- "))
            .map(|line| &line[2..])
            .collect::<Vec<_>>();

        let max = 1 << items.len();

        for dropped in 0..max {
            let mut instance = computer.clone();
            for (i, item) in items.iter().enumerate() {
                let mask = 1 << i;
                if dropped & mask != 0 {
                    send_command(&mut instance, &format!("drop {}", item));
                }
            }

            if run_until_input(&mut instance).is_none() {
                continue;
            }

            send_command(&mut instance, "inv");
            send_command(&mut instance, command);
            if let Some(output) = run_until_input(&mut instance) {
                if !output.contains("heavier") && !output.contains("lighter") {
                    println!("{}", output);
                    mem::swap(computer, &mut instance);
                    return;
                }
            }
        }
    }
}

fn run_until_input(computer: &mut Computer) -> Option<String> {
    let mut transcript = String::new();

    loop {
        match computer.run() {
            Action::Halt => break,
            Action::NeedsInput => break,
            Action::Output(value) => transcript.push(value as u8 as char),
        }
    }

    Some(transcript)
}
