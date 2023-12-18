import sys

def inclusion_exclusion(instructions):
    y = 0
    area = 0
    total_steps = 0
    for dir, steps in instructions:
        total_steps += steps
        if dir == 'R': area += steps * y
        if dir == 'L': area -= steps * y
        if dir == 'U': y += steps
        if dir == 'D': y -= steps
    return abs(area) + total_steps // 2 + 1

part1 = []
part2 = []
for line in sys.stdin.read().strip().splitlines():
    dir, steps, color = line.split()
    part1.append((dir, int(steps)))
    part2.append(("RDLU"[int(color[-2])], int(color[2:-2], 16)))

print('part1', inclusion_exclusion(part1))
print('part2', inclusion_exclusion(part2))

