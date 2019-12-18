use std::collections::VecDeque;
use std::convert::TryInto;
use std::fs;
use std::path::Path;
use std::sync::mpsc::{channel, Iter as OutputIter, Receiver, RecvError, SendError, Sender};
use std::thread;

pub type Error = Box<dyn std::error::Error>;
pub type Result<T, E = Error> = std::result::Result<T, E>;

pub struct Computer {
    instruction: usize,
    code: Vec<i64>,
    input: VecDeque<i64>,
    relative_base: i64,
}

pub struct Input(Sender<i64>);
pub struct Output(Receiver<Action>);

pub struct Io {
    input: Input,
    output: Output,
}

#[derive(Debug, Copy, Clone)]
enum Instruction {
    Halt,
    Add(Parameter, Parameter, Address),
    Mul(Parameter, Parameter, Address),
    Input(Address),
    Output(Parameter),
    Jnz(Parameter, Parameter),
    Jez(Parameter, Parameter),
    Slt(Parameter, Parameter, Address),
    Seq(Parameter, Parameter, Address),
    Reb(Parameter),
}

#[derive(Debug, Copy, Clone)]
enum Parameter {
    Address(Address),
    Value(i64),
}

#[derive(Debug, Copy, Clone)]
enum Address {
    Position(i64),
    Relative(i64),
}

#[derive(Debug, Copy, Clone)]
pub enum Action {
    Output(i64),
    NeedsInput,
    Halt,
}

impl Computer {
    pub fn new(code: Vec<i64>) -> Computer {
        Computer {
            instruction: 0,
            code,
            input: VecDeque::new(),
            relative_base: 0,
        }
    }

    pub fn load(path: impl AsRef<Path>) -> Result<Computer> {
        let text = fs::read_to_string(path)?;
        let code = text
            .lines()
            .next()
            .unwrap()
            .split(',')
            .map(|w| w.parse().map_err(Into::into))
            .collect::<Result<Vec<_>>>()?;
        Ok(Computer::new(code))
    }

    fn validate_index(&mut self, index: usize) {
        if index >= self.code.len() {
            self.code.resize(index + 1, 0);
        }
    }

    fn index(&self, address: Address) -> usize {
        match address {
            Address::Position(index) => index.try_into().unwrap(),
            Address::Relative(relative) => {
                let index = self.relative_base as i64 + relative;
                index.try_into().unwrap()
            }
        }
    }

    fn read(&mut self, address: Address) -> i64 {
        let index = self.index(address);
        self.validate_index(index);
        self.code[index]
    }

    fn write(&mut self, value: i64, address: Address) {
        let index = self.index(address);
        self.validate_index(index);
        self.code[index] = value;
    }

    fn evaluate(&mut self, param: Parameter) -> i64 {
        match param {
            Parameter::Address(address) => self.read(address),
            Parameter::Value(value) => value,
        }
    }

    fn fetch_int(&mut self) -> i64 {
        let value = self.read(Address::Position(self.instruction as i64));
        self.instruction += 1;
        value
    }

    fn parameter_kind(digit: i64) -> fn(i64) -> Parameter {
        match digit {
            0 => |value| Parameter::Address(Address::Position(value)),
            1 => Parameter::Value,
            2 => |value| Parameter::Address(Address::Relative(value)),
            _ => panic!("Invalid parameter kind: {}", digit),
        }
    }

    fn fetch_instruction(&mut self) -> Instruction {
        let instruction = self.fetch_int();

        let a = Self::parameter_kind(digit(instruction, 2));
        let b = Self::parameter_kind(digit(instruction, 3));
        let c = Self::parameter_kind(digit(instruction, 4));

        let op = instruction % 100;

        match op {
            99 => Instruction::Halt,
            1 => Instruction::Add(
                a(self.fetch_int()),
                b(self.fetch_int()),
                c(self.fetch_int()).address().unwrap(),
            ),
            2 => Instruction::Mul(
                a(self.fetch_int()),
                b(self.fetch_int()),
                c(self.fetch_int()).address().unwrap(),
            ),
            3 => Instruction::Input(a(self.fetch_int()).address().unwrap()),
            4 => Instruction::Output(a(self.fetch_int())),
            5 => Instruction::Jnz(a(self.fetch_int()), b(self.fetch_int())),
            6 => Instruction::Jez(a(self.fetch_int()), b(self.fetch_int())),
            7 => Instruction::Slt(
                a(self.fetch_int()),
                b(self.fetch_int()),
                c(self.fetch_int()).address().unwrap(),
            ),
            8 => Instruction::Seq(
                a(self.fetch_int()),
                b(self.fetch_int()),
                c(self.fetch_int()).address().unwrap(),
            ),
            9 => Instruction::Reb(a(self.fetch_int())),
            _ => panic!("Invalid opcode: {}", op),
        }
    }

    fn rollback(&mut self, instruction: Instruction) {
        let int_count = instruction.size();
        self.instruction -= int_count;
    }

    pub fn provide_input(&mut self, input: impl IntoIterator<Item = i64>) {
        self.input.extend(input);
    }

    pub fn run(&mut self) -> Action {
        loop {
            let instruction = self.fetch_instruction();

            match instruction {
                Instruction::Halt => return Action::Halt,
                Instruction::Add(a, b, target) => {
                    let lhs = self.evaluate(a);
                    let rhs = self.evaluate(b);
                    self.write(lhs + rhs, target);
                }
                Instruction::Mul(a, b, target) => {
                    let lhs = self.evaluate(a);
                    let rhs = self.evaluate(b);
                    self.write(lhs * rhs, target);
                }
                Instruction::Input(target) => {
                    if let Some(value) = self.input.pop_front() {
                        self.write(value, target);
                    } else {
                        self.rollback(instruction);
                        return Action::NeedsInput;
                    }
                }
                Instruction::Output(parameter) => {
                    let value = self.evaluate(parameter);
                    return Action::Output(value);
                }
                Instruction::Jnz(a, target) => {
                    let value = self.evaluate(a);
                    if value != 0 {
                        self.instruction = self.evaluate(target).try_into().unwrap();
                    }
                }
                Instruction::Jez(a, target) => {
                    let value = self.evaluate(a);
                    if value == 0 {
                        self.instruction = self.evaluate(target).try_into().unwrap();
                    }
                }
                Instruction::Slt(a, b, target) => {
                    let lhs = self.evaluate(a);
                    let rhs = self.evaluate(b);
                    self.write(if lhs < rhs { 1 } else { 0 }, target);
                }
                Instruction::Seq(a, b, target) => {
                    let lhs = self.evaluate(a);
                    let rhs = self.evaluate(b);
                    self.write(if lhs == rhs { 1 } else { 0 }, target);
                }
                Instruction::Reb(offset) => {
                    self.relative_base += self.evaluate(offset);
                }
            }
        }
    }

    pub fn run_async(mut self) -> Io {
        let (input, receiver) = channel();
        let (sender, output) = channel();

        thread::spawn(move || loop {
            let action = self.run();
            match sender.send(action) {
                Ok(()) => {}
                Err(e) => {
                    eprintln!("Failed to send to output: {}", e);
                    break;
                }
            }

            match action {
                Action::Halt => break,
                Action::NeedsInput => match receiver.recv() {
                    Ok(input) => self.provide_input(Some(input)),
                    Err(error) => panic!("Input channel closed: {}", error),
                },
                Action::Output(_) => {}
            }
        });

        Io {
            input: Input(input),
            output: Output(output),
        }
    }
}

impl Input {
    pub fn send(&self, value: i64) -> Result<(), SendError<i64>> {
        self.0.send(value)
    }
}

impl Output {
    pub fn recv(&self) -> Result<Action, RecvError> {
        self.0.recv()
    }

    pub fn iter(&self) -> OutputIter<Action> {
        self.0.iter()
    }
}

impl Io {
    pub fn send(&self, value: i64) -> Result<(), SendError<i64>> {
        self.input.send(value)
    }

    pub fn recv(&self) -> Result<Action, RecvError> {
        self.output.recv()
    }

    pub fn iter(&self) -> OutputIter<Action> {
        self.output.iter()
    }
}

impl Instruction {
    pub fn size(self) -> usize {
        match self {
            Instruction::Halt => 1,
            Instruction::Add(_, _, _) => 4,
            Instruction::Mul(_, _, _) => 4,
            Instruction::Input(_) => 2,
            Instruction::Output(_) => 2,
            Instruction::Jnz(_, _) => 3,
            Instruction::Jez(_, _) => 3,
            Instruction::Slt(_, _, _) => 4,
            Instruction::Seq(_, _, _) => 4,
            Instruction::Reb(_) => 2,
        }
    }
}

impl Action {
    pub fn output(self) -> i64 {
        match self {
            Action::Output(value) => value,
            _ => panic!("Expected Action::Output, found {:?}", self),
        }
    }
}

fn digit(value: i64, digit: u32) -> i64 {
    (value / 10i64.pow(digit)) % 10
}

pub fn compute(code: Vec<i64>, input: impl IntoIterator<Item = i64>) -> Vec<i64> {
    let mut computer = Computer::new(code);
    computer.provide_input(input);
    let mut output = Vec::new();

    loop {
        match computer.run() {
            Action::Halt => return output,
            Action::Output(value) => output.push(value),
            Action::NeedsInput => panic!("insufficient input provided"),
        }
    }
}

impl Parameter {
    pub fn address(self) -> Option<Address> {
        match self {
            Parameter::Address(address) => Some(address),
            _ => None,
        }
    }
}
