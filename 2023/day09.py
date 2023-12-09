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
        deltas.append([prev[i] - prev[ i-1 ] for i in range(1, len(prev))])

    # Forwards
    next = 0
    for i in reversed(range(len(deltas)-1)):
        next = deltas[i][-1] + next

    # Backwards
    prev = 0
    for i in reversed(range(len(deltas)-1)):
        prev = deltas[i][0] - prev

    part1 += next
    part2 += prev

print('part1', part1)
print('part2', part2)
