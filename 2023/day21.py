import sys
from collections import deque

grid = sys.stdin.read().strip().splitlines()

height = len(grid)
width = len(grid[0])
assert width == height
N = width

def find_start():
    for y in range(N):
        for x in range(N):
            if grid[y][x] == 'S': return (x, y)
    return (N//2, N//2)

def count_distances(start, steps):
    queue = deque()
    queue.append((start, 0))
    visited = set()
    visited.add(start)

    deltas = [(0, 1), (0, -1), (1, 0), (-1, 0)]
    count = 0

    while len(queue) > 0:
        curr, curr_distance = queue.popleft()

        if curr_distance % 2 == steps % 2: count += 1

        distance = curr_distance + 1
        if distance > steps: continue

        for dx, dy in deltas:
            nx = curr[0] + dx
            ny = curr[1] + dy
            if grid[ny % N][nx % N] == '#': continue
            next = (nx, ny)
            if next in visited: continue
            visited.add(next)
            queue.append((next, distance))

    return count

steps = 26501365

start = find_start()
print('part1', count_distances(start, 64))

a = count_distances(start, (steps % N) + N * 0)
b = count_distances(start, (steps % N) + N * 1)
c = count_distances(start, (steps % N) + N * 2)

ab = b-a
bc = c-b
abbc = bc-ab

def count_distances_closed(t):
    return a + ab * t + abbc * t * (t-1) // 2

assert count_distances_closed(0) == a, count_distances_closed(0)
assert count_distances_closed(1) == b, count_distances_closed(1)
assert count_distances_closed(2) == c, count_distances_closed(2)

print('part2', count_distances_closed(steps // N))

