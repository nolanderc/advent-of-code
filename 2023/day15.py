import sys

string = sys.stdin.read().strip()
assert '\n' not in string

def hash(text):
    h = 0
    for byte in bytes(text, 'utf-8'):
        h += byte
        h *= 17
        h %= 256
    return h

print('part1', sum(hash(step) for step in string.split(',')))

boxes = [{} for _ in range(256)]

for step in string.split(','):
    if step.endswith('-'):
        label = step[:-1]
        box = boxes[hash(label)]
        if label in box:
            box.pop(label)
    else:
        label, focal = step.split('=')
        boxes[hash(label)][label] = int(focal)

part2 = 0
for i, box in enumerate(boxes):
    for j, lens in enumerate(box.values()):
        part2 += (i+1) * (j+1) * lens

print('part2', part2)
