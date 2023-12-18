import sys

grid = [list(map(int, line)) for line in sys.stdin.read().strip().splitlines()]

height = len(grid)
width = len(grid[0])

def find_loss(min_steps, max_steps):
    queues = [[] for _ in range(10)]
    visited = {}

    loss = 0

    endpos = (width-1, height-1)

    def push(pos, dir, steps):
        dx, dy = dir
        x = pos[0] + dx
        y = pos[1] + dy
        if 0 <= x < width and 0 <= y < height:
            cost = loss + grid[y][x]
            key = (x, y, dx, dy, steps)
            if key in visited and cost >= visited[key]: return
            visited[key] = cost
            queues[cost % 10].append(((x, y), dir, steps))

    queues[0].append(((0, 0), (1, 0), 0))
    queues[0].append(((0, 0), (0, 1), 0))

    while any(len(queue) > 0 for queue in queues):
        queue = queues[loss % 10]
        for pos, dir, steps in queue:
            if steps >= min_steps:
                if pos == endpos:
                    return loss
                push(pos, (dir[1], -dir[0]), 1)
                push(pos, (-dir[1], dir[0]), 1)
            if steps < max_steps:
                push(pos, dir, steps+1)
        queue.clear()
        loss += 1

print('part1', find_loss(0, 3))
print('part2', find_loss(4, 10))
