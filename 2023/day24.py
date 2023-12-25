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

lines = sys.stdin.read().strip().splitlines()

hails = []
for line in lines:
    x, y, z, vx, vy, vz = ints(line)
    hails.append(((x, y, z), (vx, vy, vz)))

boundary = (200000000000000, 400000000000000)
# boundary = (7, 27)

def det(a, b, c, d):
    # a b
    # c d
    return a * d - b * c

def ray_line_intersection(a, b):
    ap, ad = a
    bp, bd = b
    t1 = det(ap[0] - bp[0], -bd[0],
             ap[1] - bp[1], -bd[1])
    t2 = det(-ad[0], -bd[0],
             -ad[1], -bd[1])
    if t2 == 0 or t1 * t2 < 0: return None
    return (t1, t2)

def line_intersection_2d(a, b):
    at = ray_line_intersection(a, b)
    bt = ray_line_intersection(b, a)
    if at is None or bt is None: return False

    xlow = boundary[0] - a[0][0]
    ylow = boundary[0] - a[0][1]
    xhigh = boundary[1] - a[0][0]
    yhigh = boundary[1] - a[0][1]
    
    xmin = min(xlow * at[1], xhigh * at[1])
    xmax = max(xlow * at[1], xhigh * at[1])
    
    ymin = min(ylow * at[1], yhigh * at[1])
    ymax = max(ylow * at[1], yhigh * at[1])
    
    if not (xmin <= a[1][0] * at[0] <= xmax): return False
    if not (ymin <= a[1][1] * at[0] <= ymax): return False

    return True

part1 = 0
for i in range(len(hails)):
    for j in range(i+1, len(hails)):
        a = hails[i]
        b = hails[j]
        if line_intersection_2d(a, b):
            part1 += 1
print('part1', part1)



# o + d * t = p + r * t

# (d - r) * t + (o-p) = 0
# (d - r) * t = p - o
# t = (p - o) / (d - r)

# p = o + (d-r)*t
# r = (o-p)/t + d

# r = ((o1 + d1*a) - (o2 + d2*b)) / (a - b) = (o2-o3 + d2*b - d3*c) / (b-c)

# (o1 - o2 + d1*a - d2*b) / (a-b) = (o2 - o3 + d2*b - d3*c) / (b-c)
# (o1 - o2 + d1*a - d2*b) * (b-c) = (o2 - o3 + d2*b - d3*c) * (a-b)
# (o1 - o2 + d1*a - d2*b) * (b-c) - (o2 - o3 + d2*b - d3*c) * (a-b) = 0
# (o1 - o2 + d1*a - d2*b) * (b-c) + (o2 - o3 + d2*b - d3*c) * (b-a) = 0
# (o1*b - o2*b + d1*a*b - d2*b*b) - (o1*c - o2*c + d1*a*c - d2*b*c) + (o2*b - o3*b + d2*b*b - d3*b*c) - (o2*a - o3*a + d2*a*b - d3*a*c) = 0
#  o1*b - o2*b + d1*a*b - d2*b*b  -  o1*c + o2*c - d1*a*c + d2*b*c  +  o2*b - o3*b + d2*b*b - d3*b*c  -  o2*a + o3*a - d2*a*b + d3*a*c  = 0
#  o1*b        + d1*a*b           -  o1*c + o2*c - d1*a*c + d2*b*c          - o3*b          - d3*b*c  -  o2*a + o3*a - d2*a*b + d3*a*c  = 0

# (o3-o2)*a + (o1-o3)*b + (o2-o1)*c + (d1-d2)*a*b + (d2-d3)*b*c + (d3-d1)*a*c = 0

def equation(i, j, k):
    ap, ad = hails[i]
    bp, bd = hails[j]
    cp, cd = hails[k]

    print()
    print(i, j, k)

    for x in range(3):
        o1 = ap[x]
        o2 = bp[x]
        o3 = cp[x]
        d1 = ad[x]
        d2 = bd[x]
        d3 = cd[x]

        print(f'{o3-o2}a + {o1-o3}b + {o2-o1}c + {d1-d2}ab + {d2-d3}bc + {d3-d1}ac = 0')

equation(0, 1, 2)

# for i in range(len(hails)):
#     for j in range(i+1, len(hails)):
#         for k in range(j+1, len(hails)):
#             equation(i, j, k)

# Plugging the above equation into wolfram alpha
a = 582609869063
b = 910921774718
c = 317908000015

# Sample:
# a = 5
# b = 3
# c = 4

# r = ((o1 + d1*a) - (o2 + d2*b)) / (a - b)
ao, ad = hails[0]
bo, bd = hails[1]

ai = (ao[0] + ad[0] * a, ao[1] + ad[1] * a, ao[2] + ad[2] * a)
bi = (bo[0] + bd[0] * b, bo[1] + bd[1] * b, bo[2] + bd[2] * b)

rx = (ai[0] - bi[0]) // (a - b)
ry = (ai[1] - bi[1]) // (a - b)
rz = (ai[2] - bi[2]) // (a - b)

px = ai[0] - rx * a
py = ai[1] - ry * a
pz = ai[2] - rz * a

print(px, py, pz)
print(rx, ry, rz)

print('part2', sum((px, py, pz)))


