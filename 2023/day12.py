import sys

lines = sys.stdin.read().strip().splitlines()

part1 = 0
part2 = 0

for line in lines:
    records, groups = line.split()
    groups = list(map(int, groups.split(',')))
    unknowns = records.count('?')

    cache = [-1] * (len(records) * len(groups))

    def possibilities(i, next_group):
        global records, groups, cache

        if next_group == len(groups): return 0 if '#' in records[i:] else 1
        if i >= len(records): return 0

        key = i + next_group * len(records)
        if cache[key] >= 0: return cache[key]

        count = 0

        # If we don't place the next group here
        if records[i] != '#':
            count += possibilities(i+1, next_group)

        # If we place the next group here
        size = groups[next_group]
        if i+size <= len(records) and '.' not in records[i:i+size]:
            if i+size == len(records) or records[i+size] != '#':
                count += possibilities(i+size+1, next_group+1)

        cache[key] = count
        return count
        
    part1 += possibilities(0, 0)

    records = '?'.join([records] * 5)
    groups = groups * 5
    cache = [-1] * (len(records) * len(groups))

    part2 += possibilities(0, 0)

print('part1', part1)
print('part2', part2)
