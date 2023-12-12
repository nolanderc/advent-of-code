import sys

grid = sys.stdin.read().strip().splitlines()

height = len(grid)
width = len(grid[0])

galaxies = []
rows = set()
cols = set()

for row in range(height):
    for col in range(width):
        if grid[row][col] == '#':
            galaxies.append((row, col))
            rows.add(row)
            cols.add(col)

def distance_sum(expansion):
    target_row = {}
    row_expansion = 0
    for row in range(height):
        if row not in rows: row_expansion += expansion - 1
        target_row[row] = row + row_expansion

    target_col = {}
    col_expansion = 0
    for col in range(width):
        if col not in cols: col_expansion += expansion - 1
        target_col[col] = col + col_expansion

    expanded_galaxies = [(target_row[row], target_col[col]) for row, col in galaxies]

    def manhattan(a, b):
        return abs(a[0] - b[0]) + abs(a[1] - b[1])

    total = 0
    for i in range(len(galaxies)):
        for j in range(i+1, len(galaxies)):
            total += manhattan(expanded_galaxies[i], expanded_galaxies[j])
    return total

print('part1', distance_sum(1))
print('part2', distance_sum(int(1e6)))

