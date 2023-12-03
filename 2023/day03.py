import sys
from collections import defaultdict

lines = sys.stdin.read().strip().splitlines()

numbers = []
symbols = []

for row, line in enumerate(lines):
    col = 0
    while col < len(line):
        num_start = col
        while col < len(line) and line[col].isdigit():
            col += 1
        if num_start != col:
            number = int(line[num_start:col])
            numbers.append((number, row, num_start, col))
        elif line[col] != '.':
            symbols.append((line[col], row, col))
            col += 1
        else:
            col += 1

symbol_positions = { (row, col): s for s, row, col in symbols }
symbol_numbers = defaultdict(list)

part1 = 0

for number, row, colstart, colend in numbers:
    adjacent_to_symbol = False
    for r in range(row-1, row+2):
        for c in range(colstart-1, colend+1):
            if (r, c) in symbol_positions:
                adjacent_to_symbol = True
                symbol_numbers[(r, c)].append(number)

    if adjacent_to_symbol:
        part1 += number

part2 = 0
for symbol, row, col in symbols:
    if symbol == '*':
        adjacent_symbols = symbol_numbers[(row, col)]
        if len(adjacent_symbols) == 2:
            part2 += adjacent_symbols[0] * adjacent_symbols[1]

print(part1)
print(part2)


