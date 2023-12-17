import sys

grid = sys.stdin.read().strip().splitlines()
height = len(grid)
width = len(grid[0])

def find_energized(startpos, startdir):
    stack = [(startpos, startdir)]
    visited = set(stack)

    def push(pos, dir):
        pos = (pos[0] + dir[0], pos[1] + dir[1])

        if 0 <= pos[0] < width and 0 <= pos[1] < height:
            if (pos, dir) not in visited:
                visited.add((pos, dir))
                stack.append((pos, dir))

    while len(stack) > 0:
        pos, dir = stack.pop()

        cell = grid[pos[1]][pos[0]]

        if cell == '-' and dir[1] != 0:
            push(pos, (-1, 0))
            push(pos, (1, 0))
        elif cell == '|' and dir[0] != 0:
            push(pos, (0, -1))
            push(pos, (0, 1))
        elif cell == '/':
            push(pos, (-dir[1], -dir[0]))
        elif cell == '\\':
            push(pos, (dir[1], dir[0]))
        else:
            push(pos, dir)

    return set(pos for pos, _ in visited)

print('part1', len(find_energized((0,0), (1,0))))

part2 = 0
for x in range(width):
    part2 = max(part2, len(find_energized((x, 0), (0, 1))))
    part2 = max(part2, len(find_energized((x, height-1), (0, -1))))
for y in range(height):
    part2 = max(part2, len(find_energized((0, y), (1, 0))))
    part2 = max(part2, len(find_energized((width-1, y), (-1, 0))))
print('part2', part2)
