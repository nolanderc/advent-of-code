import sys
from collections import deque

lines = sys.stdin.read().strip().splitlines()

bricks = []
for line in lines:
    start, end = line.split('~')
    start = tuple(map(int, start.split(',')))
    end = tuple(map(int, end.split(',')))
    bricks.append((start, end))

bricks.sort(key=lambda x: x[0][2])

minx = bricks[0][0][0]
maxx = bricks[0][0][0]
miny = bricks[0][0][1]
maxy = bricks[0][0][1]

for ((sx, sy, _), (ex, ey, _)) in bricks:
    minx = min(minx, sx, ex)
    maxx = max(maxx, sx, ex)
    miny = min(miny, sy, ey)
    maxy = max(maxy, sy, ey)

width = maxx - minx + 1
height = maxy - miny + 1

heightmap = [(0, None)] * width * height
supported_by = [set() for _ in range(len(bricks))]
supporting = [set() for _ in range(len(bricks))]

for i, ((sx, sy, sz), (ex, ey, ez)) in enumerate(bricks):
    maxz = 0
    for y in range(sy, ey+1):
        for x in range(sx, ex+1):
            z, _ = heightmap[x + y * width]
            maxz = max(maxz, z)

    newz = maxz + (ez - sz + 1)
    assert newz <= ez

    for y in range(sy, ey+1):
        for x in range(sx, ex+1):
            z, support = heightmap[x + y * width]
            if z == maxz and support is not None:
                supported_by[i].add(support)
                supporting[support].add(i)

            heightmap[x + y * width] = (newz, i)

part1 = 0
for above in supporting:
    if all(len(supported_by[x]) >= 2 for x in above):
        part1 += 1
print('part1', part1)

part2 = 0
for i in range(len(bricks)):
    fallen = set()
    fallen.add(i)

    fallen_below = [0] * len(bricks)

    queue = deque()
    queue.append(i)

    while len(queue) != 0:
        curr = queue.popleft()
        for above in supporting[curr]:
            fallen_below[above] += 1
            if fallen_below[above] == len(supported_by[above]):
                fallen.add(above)
                queue.append(above)
                part2 += 1
print('part2', part2)
