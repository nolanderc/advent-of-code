import sys
import random

lines = sys.stdin.read().strip().splitlines()

edges = []
vertices = set()

for line in lines:
    source, targets = line.split(': ')
    vertices.add(source)
    for target in targets.split():
        vertices.add(target)
        edges.append((source, target))

E = len(edges)
V = len(vertices)

while True:
    parents = {}
    sizes = {}

    def find(x):
        if x not in parents:
            parents[x] = x
            sizes[x] = 1
        else: 
            parent = parents[x]
            while parent != x:
                grandparent = parents[parent]
                parents[x] = grandparent
                x, parent = parent, grandparent
        return x

    def union(a, b):
        a = find(a)
        b = find(b)
        if a == b: return False
        asize = sizes[a]
        bsize = sizes[b]
        if asize >= bsize:
            parents[b] = a
            sizes[a] = asize + bsize
        else:
            parents[a] = b
            sizes[b] = asize + bsize
        return True

    random.shuffle(edges)

    count = V
    i = 0
    while count > 2:
        source, target = edges[i]
        if union(source, target):
            count -= 1
        i += 1

    cut = []
    for source, target in edges[i:]:
        if find(source) != find(target):
            cut.append((source, target))

    if len(cut) == 3:
        source, target = cut[0]
        a = find(source)
        b = find(target)
        print('part1', sizes[a] * sizes[b])
        break

