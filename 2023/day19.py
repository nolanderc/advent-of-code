import sys
import re

flowstext, partstext = sys.stdin.read().strip().split('\n\n')

flows = {}
for line in flowstext.splitlines():
    parts = re.findall(r'(\w+|<|>)', line)
    name = parts[0]
    rules = []
    for i in range(1, len(parts) - 1, 4):
        var, comparison, value, next = parts[i:i+4]
        rules.append((var, comparison, int(value), next))
    default = parts[-1]
    flows[name] = (rules, default)

part1 = 0

for line in partstext.splitlines():
    attrs = { m.group(1): int(m.group(2)) for m in re.finditer(r'(\w+)=(\d+)', line)}

    curr = 'in'
    while curr != 'A' and curr != 'R':
        rules, default = flows[curr]

        for var, comparison, value, next in rules:
            if comparison == '<' and attrs[var] < value:
                curr = next
                break;
            if comparison == '>' and attrs[var] > value:
                curr = next
                break;
        else:
            curr = default

    if curr == 'A':
        part1 += sum(attrs.values())

print('part1', part1)

cache = {}

def accepted_combinations(flow: str, attrs: dict):
    if flow == 'R': return 0
    if flow == 'A':
        count = 1
        for min, max in attrs.values():
            count *= max - min + 1
        return count

    key = (flow, tuple(attrs.items()))
    if key in cache: return cache[key]

    rules, default = flows[flow]

    count = 0
    for var, comparison, value, next in rules:
        min, max = attrs[var]
        if comparison == '<' and min < value:
            new = attrs.copy()
            new[var] = (min, value-1)
            count += accepted_combinations(next, new)
            attrs[var] = (value, max)
        if comparison == '>' and max > value:
            new = attrs.copy()
            new[var] = (value+1, max)
            count += accepted_combinations(next, new)
            attrs[var] = (min, value)

    count += accepted_combinations(default, attrs)

    cache[key] = count
    return count

in_range = (1, 4000)
print('part2', accepted_combinations('in', { rating: in_range for rating in 'xmas' }))
