import sys
from collections import defaultdict

def card_from_char(char):
    return "0123456789TJQKA".find(char)

def extract_hands(lines):
    hands = []

    for line in lines:
        cards_char, bid = line.split()
        bid = int(bid)
        cards = [card_from_char(char) for char in cards_char]
        counts = defaultdict(lambda: 0)
        for card in cards: counts[card] += 1

        joker_count, counts[0] = counts[0], 0
        kind = sorted(counts.values(), reverse=True)
        kind[0] += joker_count
        hands.append((kind, cards, bid))

    return hands

input = sys.stdin.read().strip()
sorted_hands1 = sorted(extract_hands(input.splitlines()))
sorted_hands2 = sorted(extract_hands(input.replace('J', '0').splitlines()))

print('part1', sum((i+1) * bid for i, (_,_,bid) in enumerate(sorted_hands1)))
print('part2', sum((i+1) * bid for i, (_,_,bid) in enumerate(sorted_hands2)))




