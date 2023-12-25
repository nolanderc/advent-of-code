import sys
import re
from collections import deque, defaultdict
import math

lines = sys.stdin.read().strip().splitlines()

modules = {}
for line in lines:
    words = re.findall(r'(\w+|%|&)', line)

    kind = words[0]
    if kind == 'broadcaster':
        name, after = kind, words[1:]
    else:
        name, after = words[1], words[2:]

    modules[name] = (kind, after)

memory = {}
lows = 0
highs = 0

def clear_memory():
    for name, (kind, _) in modules.items():
        memory[name] = {} if kind == '&' else False

def push_button(trigger, goal):
    global memory, lows, highs

    queue: deque = deque([('button', True, trigger)])

    reached_goal = False

    while len(queue) > 0:
        source, low, target = queue.popleft()
        # print(source, '-low->' if low else '-high->', target)

        if low: lows += 1
        else: highs += 1

        if target not in modules:
            continue

        kind, after = modules[target]

        if low and target == goal:
            reached_goal = True

        if kind == '%' and low:
            state = memory[target]
            queue.extend((target, state, x) for x in after)
            memory[target] = not state

        if kind == '&':
            state = memory[target]
            state[source] = low
            sendlow = not any(state.values())
            queue.extend((target, sendlow, x) for x in after)
        
        if kind == 'broadcaster':
            queue.extend((target, low, x) for x in after)

    return reached_goal

clear_memory()

for _ in range(1000):
    push_button('broadcaster', None)

print('part1', lows * highs)

# print('digraph {')
# for name, (kind, after) in modules.items():
#     if kind == 'broadcaster': kind = ''
#     print(' ', name, f'[label="{kind}{name}"]')
# for name, (kind, after) in modules.items():
#     print(' ', name, '->', '{', ' '.join(after), '}')
# print('}')

clear_memory();

inputs = defaultdict(list)
for name, (kind, after) in modules.items():
    for x in after:
        inputs[x].append(name)
        if x not in modules: continue
        if modules[x][0] == '&':
            memory[x][name] = True

origins = modules['broadcaster'][1]
targets = inputs[inputs['rx'][0]]

cycles = []
for origin in origins:
    queue = deque([origin])
    visited = set()
    while len(queue) > 0:
        next = queue.popleft()
        if next in targets:
            cycles.append((origin, next))
            break
        after = modules[next][1]
        for x in after:
            if x not in visited:
                visited.add(x)
                queue.append(x)

periods = []
for trigger, goal in cycles:
    i = 1
    while not push_button(trigger, goal): i += 1
    periods.append(i)

print('part2', math.lcm(*periods))

