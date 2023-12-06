import sys
import math

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

def solve(time, distance):
    a = time
    b = distance
    # Solve: -x**2 + ax - b > 0
    # Since we want strict inequality, we round no the next/previous integer.
    # For example, if the solution is an integer, the answer to the inequality
    # is actually one more than this integer.
    x1 = int(math.floor((a - math.sqrt(a*a - 4*b)) / 2)) + 1
    x2 = int(math.ceil((a + math.sqrt(a*a - 4*b)) / 2)) - 1
    return x2 - x1 + 1

times, distances = sys.stdin.read().strip().splitlines()

total_time = ints(''.join(times.split()))[0]
total_distance = ints(''.join(distances.split()))[0]

times = ints(times)
distances = ints(distances)

part1 = 1
for time, distance in zip(times, distances):
    part1 *= solve(time, distance)
print('part1', part1)
print('part2', solve(total_time, total_distance))

