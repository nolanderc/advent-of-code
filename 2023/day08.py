import sys
import re
import math

lines = sys.stdin.read().strip().splitlines()

sequence, network = lines[0], lines[2:]

nodes = {}
for line in network:
    match = re.match(r'(\w+) = \((\w+), (\w+)\)', line)
    if match is None: raise Exception("could not parse line: " + line)
    source, left, right = match.groups()
    nodes[source] = { 'L': left, 'R': right }

current = 'AAA'
part1 = 0

while current in nodes and current != 'ZZZ':
    direction = sequence[part1 % len(sequence)]
    current = nodes[current][direction]
    part1 += 1

def find_cycle(node):
    length = 1
    maxlen = 1

    mark = node
    hare = nodes[node][sequence[0]]
    mark_depth = 0
    hare_depth = 1

    while mark != hare or mark_depth != hare_depth:
        if length == maxlen:
            mark = hare
            mark_depth = hare_depth
            maxlen *= 2
            length = 0
        hare = nodes[hare][sequence[hare_depth]]
        length += 1
        hare_depth = (hare_depth + 1) % len(sequence)

    hare = node
    hare_depth = 0
    for _ in range(length):
        hare = nodes[hare][sequence[hare_depth]]
        hare_depth = (hare_depth + 1) % len(sequence)

    mark = node
    mark_depth = 0
    while mark != hare or mark_depth != hare_depth:
        mark = nodes[mark][sequence[mark_depth]]
        mark_depth = (mark_depth + 1) % len(sequence)
        hare = nodes[hare][sequence[hare_depth]]
        hare_depth = (hare_depth + 1) % len(sequence)

    cycle = []
    for _ in range(length):
        cycle.append(hare)
        hare = nodes[hare][sequence[hare_depth % len(sequence)]]
        hare_depth += 1

    return mark_depth, cycle

starts = [node for node in nodes.keys() if node[-1] == 'A']
cycles = [find_cycle(node) for node in starts]

cycle_lengths = []

for depth, nodes in cycles:
    ends = [i for i, node in enumerate(nodes) if node[-1] == 'Z']
    assert depth + ends[-1] == len(nodes)
    cycle_lengths.append(len(nodes))

part2 = math.lcm(*cycle_lengths)

print('part1', part1)
print('part2', part2)
