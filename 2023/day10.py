import sys
from collections import defaultdict, deque

input = sys.stdin.read().strip().splitlines()

grid = defaultdict(lambda: 0)
start = None

NORTH = 1
SOUTH = 2
WEST = 4
EAST = 8

width = 0
height = 0

for row, line in enumerate(input):
    for col, cell in enumerate(line):
        if cell == 'S':
            start = (row, col)
            grid[(row, col)] = NORTH | SOUTH | WEST | EAST

        if cell == '|': grid[(row, col)] = NORTH | SOUTH
        if cell == '-': grid[(row, col)] = WEST | EAST
        if cell == 'L': grid[(row, col)] = NORTH | EAST
        if cell == 'J': grid[(row, col)] = NORTH | WEST
        if cell == '7': grid[(row, col)] = SOUTH | WEST
        if cell == 'F': grid[(row, col)] = SOUTH | EAST

        width = max(width, col+1)
        height = max(height, row+1)

directions = [NORTH, SOUTH, WEST, EAST]
opposites = { NORTH: SOUTH, SOUTH: NORTH, WEST: EAST, EAST: WEST }
deltas = { NORTH: (-1, 0), SOUTH: (1, 0), WEST: (0, -1), EAST: (0, 1) }

part1 = 0

queue = deque()
visited = { start: 0 }
edges = defaultdict(lambda: 0)

queue.append((start, 0))
while len(queue) > 0:
    curr, distance = queue.popleft()

    part1 = max(part1, distance)

    for direction in directions:
        if (grid[curr] & direction) == 0: continue
        delta = deltas[direction]
        next = (curr[0] + delta[0], curr[1] + delta[1])
        if (grid[next] & opposites[direction]) == 0: continue
        
        edges[curr] |= direction
        edges[next] |= opposites[direction]

        if next in visited: continue
        visited[next] = distance + 1
        queue.append((next, distance + 1))

expanded = []

for row in range(height):
    A = ""
    B = ""
    C = ""

    for col in range(width):
        dirs = edges[(row, col)] if (row, col) in edges else 0
        A += "..." if (dirs & NORTH) == 0 else ".|."

        B += "." if (dirs & WEST) == 0 else '-'
        B += "." if dirs == 0 else '+'
        B += "." if (dirs & EAST) == 0 else '-'

        C += "..." if (dirs & SOUTH) == 0 else ".|."

    expanded.append(A)
    expanded.append(B)
    expanded.append(C)

outside = set()
stack = [(0, 0)]
outside.add((0, 0))
while len(stack) != 0:
    row, col = stack.pop()
    for delta in deltas.values():
        nrow = row + delta[0]
        ncol = col + delta[1]
        if nrow < 0 or nrow >= 3 * height: continue
        if ncol < 0 or ncol >= 3 * width: continue
        if expanded[nrow][ncol] != '.': continue

        next = (nrow, ncol)
        if next in outside: continue
        outside.add(next)
        stack.append(next)

# Print tiles on the outside 
if False:
    for row, line in enumerate(expanded):
        for col, cell in enumerate(line):
            print('O' if (row, col) in outside else cell, end='')
        print()

part2 = 0
for row in range(height):
    for col in range(width):
        curr = (row, col)
        if (row, col) in edges or (row * 3 + 1, col * 3 + 1) in outside: continue
        part2 += 1

print('part1', max(visited.values()))
print('part2', part2)
