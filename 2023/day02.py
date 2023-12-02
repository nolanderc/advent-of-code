import sys
import functools

games = sys.stdin.read().strip().splitlines()

part1 = 0
part1_cube_counts = { 'red': 12, 'green': 13, 'blue': 14 }

part2 = 0

for game in games:
    header, rounds = game.split(': ')

    id = int(list(header.split(' '))[-1])

    part1_valid_game = True

    fewest_possible = { 'red': 0, 'green': 0, 'blue': 0 }

    for round in rounds.split('; '):
        samples = round.split(', ')
        for count, color in (tuple(sample.split(' ')) for sample in samples):
            count = int(count)
            if count > part1_cube_counts[color]:
                part1_valid_game = False
            fewest_possible[color] = max(fewest_possible[color], count)
    
    if part1_valid_game: part1 += id

    part2 += functools.reduce(lambda x, y: x*y, fewest_possible.values())

print(part1)
print(part2)
