import sys
import itertools

def ints(line):
    i = 0
    res = []
    while i < len(line):
        if line[i].isdigit() or (line[i] == '-' and line[i+1].isdigit()):
            j = i+1
            while j < len(line) and line[j].isdigit():
                j += 1
            res.append(int(line[i:j]))
            i = j
        else:
            i += 1
    return res


groups = sys.stdin.read().strip().split("\n\n")

seeds, groups = groups[0], groups[1:]
seeds = ints(seeds)

part1 = list(seeds)
part2 = [(seeds[i], seeds[i]+seeds[i+1]) for i in range(0, len(seeds), 2)]

for group in groups:
    name, map = group.split(' map:\n')
    rows = [ints(row) for row in map.split('\n')]

    for i, value in enumerate(part1):
        for target, source, count in rows:
            if source <= value and value < source+count:
                part1[i] = target + (value - source)
                break

    old_ranges = list(part2)
    new_ranges = []

    while len(old_ranges) != 0:
        start, end = old_ranges.pop()
        for target, source, count in rows:
            overlap_start = max(start, source)
            overlap_end = min(end, source+count)
            if overlap_start < overlap_end:
                if start < overlap_start: old_ranges.append((start, overlap_start))
                delta = target - source
                new_ranges.append((overlap_start+delta, overlap_end+delta))
                if overlap_end < end: old_ranges.append((overlap_end, end))
                break
        else:
            new_ranges.append((start, end))

    part2 = new_ranges

print('part1:', min(part1))
print('part2:', min(a for a, _ in part2))
