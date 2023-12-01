import sys

lines = [line.strip() for line in sys.stdin]

digits1 = list("0123456789")
digits2 = digits1 + ["one", "two", "three", "four", "five", "six", "seven", "eight", "nine"]

def find_first(line: str, digits):
    return min([(x if (x := line.find(digit)) >= 0 else len(line), digit) for digit in digits])[1]

def find_last(line: str, digits):
    return max([(line.rfind(digit), digit) for digit in digits])[1]

def parse(digit: str):
    for i, s in enumerate(digits2):
        if digit == s:
            if i < 10: return i
            return i - 9

part1 = 0
part2 = 0

for line in lines:
    if not line: continue
    part1 += 10 * parse(find_first(line, digits1)) + parse(find_last(line, digits1))
    part2 += 10 * parse(find_first(line, digits2)) + parse(find_last(line, digits2))

print('part1', part1)
print('part2', part2)
 
