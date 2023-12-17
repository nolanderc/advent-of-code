import sys
from copy import deepcopy

grid = sys.stdin.read().strip().splitlines()
grid = [list(line) for line in grid]

height = len(grid)
width = len(grid[0])
assert width == height
N = width

grid = [grid[row][col] for col in range(N) for row in range(N)]
grid = bytearray([ord(ch) for ch in grid])

empty = ord('.')
round = ord('O')
square = ord('#')

part1 = 0
for col in range(width):
    target = 0
    for row in range(height):
        cell = grid[col * N + row]
        if cell == round:
            part1 += height - target
            target += 1
        if cell == square:
            target = row+1
print('part1', part1)

new_grid = grid.copy()

def north_and_rotate():
    global grid, new_grid

    for col in range(width):
        target = 0
        for row in range(height):
            cell = grid[col * N + row]

            if cell == square:
                target = row + 1
                new_grid[(height - row - 1) * N + col] = square
            else:
                new_grid[(height - row - 1) * N + col] = empty
                if cell == round:
                    new_grid[(height - target - 1) * N + col] = round
                    target += 1

    grid, new_grid = new_grid, grid

def cycle():
    north_and_rotate()
    north_and_rotate()
    north_and_rotate()
    north_and_rotate()

states = { bytes(grid): 0 }

cycles = 1000000000
i = 0
while i < cycles:
    cycle()
    i += 1
    formatted = bytes(grid)

    if formatted in states:
        length = i - states[formatted]
        remaining = cycles - i
        skip = (remaining // length) * length
        i += skip
        while i < cycles:
            cycle()
            i += 1
        break
    states[formatted] = i

part2 = 0
for row in range(height):
    for col in range(width):
        if grid[col * N + row] == round:
            part2 += height - row
        
print('part2', part2)
