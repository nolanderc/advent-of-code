import sys
from collections import defaultdict

grid = sys.stdin.read().strip().splitlines()
height = len(grid)
width = len(grid[0])
assert width == height
N = width

def longest_path(with_slopes):
    deltas = [(0,1), (0,-1), (1,0), (-1,0)]
    def neighbours(pos):
        x, y = pos

        directions = deltas
        if with_slopes:
            cell = grid[y][x] 
            if cell == '^': directions = [(0, -1)]
            if cell == 'v': directions = [(0, 1)]
            if cell == '<': directions = [(-1, 0)]
            if cell == '>': directions = [(1, 0)]

        for dx, dy in directions:
            nx = x + dx
            ny = y + dy
            if 0 <= nx < N and 0 <= ny < N:
                if grid[ny][nx] != '#':
                    yield (nx, ny)

    start = (0,0)
    goal = (0, N-1)
    for x in range(N):
        if grid[0][x] != '#': start = (x, 0)
        if grid[-1][x] != '#': goal = (x, N-1)

    junctions = []
    junctions.append(start)
    for y in range(N):
        for x in range(N):
            if grid[y][x] == '.':
                entries = 0
                for nx, ny in neighbours((x, y)):
                    if grid[ny][nx] != '#':
                        entries += 1
                if entries > 2:
                    junctions.append((x, y))
    junctions.append(goal)

    edges = defaultdict(list)

    for source in junctions:
        for curr in neighbours(source):
            last = source
            found = True
            distance = 1
            while curr not in junctions:
                for next in neighbours(curr):
                    if next != last:
                        last = curr
                        curr = next
                        distance += 1
                        break
                else:
                    found = False
                    break
            if found:
                edges[source].append((curr, distance))

    def dfs(source, visited):
        if source == goal: return 0
        if source in visited: return None

        longest = None

        visited.add(source)
        for target, distance in edges[source]:
            cost = dfs(target, visited)
            if cost is None: continue
            if longest is None: longest = distance + cost
            else: longest = max(longest, distance + cost)
        visited.remove(source)

        return longest
    
    return dfs(start, set())

print('part1', longest_path(True))
print('part2', longest_path(False))

