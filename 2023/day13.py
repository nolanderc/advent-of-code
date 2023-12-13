import sys

groups = [group.splitlines() for group in sys.stdin.read().strip().split('\n\n')]

part1 = 0
part2 = 0

for group in groups:
    mirrors = set()

    height = len(group)
    width = len(group[0])

    for row, line in enumerate(group):
        for col, cell in enumerate(line):
            if cell == '#':
                mirrors.add((row, col))


    for col in range(width-1):
        invalid = []
        for y, x in mirrors:
            reflected = col + 1 - (x - col)
            if 0 <= reflected < width and (y, reflected) not in mirrors:
                invalid.append((y, x))
        if len(invalid) == 0: part1 += col + 1
        if len(invalid) == 1: part2 += col + 1

    for row in range(height-1):
        invalid = []
        for y, x in mirrors:
            reflected = row + 1 - (y - row)
            if 0 <= reflected < height and (reflected, x) not in mirrors:
                invalid.append((y, x))
        if len(invalid) == 0: part1 += (row + 1) * 100
        if len(invalid) == 1: part2 += (row + 1) * 100

print('part1', part1)
print('part2', part2)

