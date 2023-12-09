import sys

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

histories = [ints(l) for l in sys.stdin if len(l.strip()) != 0]

part1 = 0
part2 = 0

for history in histories:
    deltas = [history]
    while any(delta != 0 for delta in deltas[-1]):
        prev = deltas[-1]
        new_delta = [prev[i] - prev[ i-1 ] for i in range(1, len(prev))]
        deltas.append(new_delta)

    # Forwards
    deltas[-1].append(0)
    for i in reversed(range(1, len(deltas))):
        deltas[i-1].append(deltas[i-1][-1] + deltas[i][-1])

    # Backwards
    deltas[-1].insert(0, 0)
    for i in reversed(range(1, len(deltas))):
        deltas[i-1].insert(0, deltas[i-1][0] - deltas[i][0])

    part1 += deltas[0][-1]
    part2 += deltas[0][0]

print('part1', part1)
print('part2', part2)
