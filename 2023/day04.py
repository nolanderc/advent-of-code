import sys

lines = sys.stdin.read().strip().splitlines()

part1 = 0
part2 = 0

copies = [1] * len(lines)

for line in lines:
    header, lists = line.split(':')
    card = int(list(header.split())[-1])
    winning, owned = lists.split('|')
    winning = list(int(x) for x in winning.strip().split())
    owned = list(int(x) for x in owned.strip().split())

    matches = 0
    for n in owned:
        if n in winning:
            matches += 1

    score = 2**(matches-1) if matches > 0 else 0
    part1 += score

    part2 += copies[card-1]
    for i in range(card, card+matches):
        copies[i] += copies[card-1]

print(part1)
print(part2)
