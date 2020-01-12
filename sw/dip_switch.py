import math
import itertools
from collections.abc import Iterable

r = 4.7e3
U = 5

possible_resistors = [ 1e3, 1.5e3, 2.2e3, 4.7e3, 10e3, 22e3, 27e3, 33e3, 47e3, 100e3, 220e3 ]

tolerance = 0.01

def parallel(*args):
    def _parallel(r1, r2):
        return (r1 * r2) / (r1 + r2)

    if len(args) == 1 and isinstance(args[0], Iterable):
        args = args[0]

    if len(args) == 0:
        return math.inf
    elif len(args) == 1:
        return args[0]
    elif len(args) == 2:
        return _parallel(args[0], args[1])
    else:
        return parallel(_parallel(args[0], args[1]), *args[2:])

def main():
    max_min_dist = 0
    best_configuration = None
    best_points = None

    k = 1
    k_max = len(possible_resistors)**4

    for r1 in possible_resistors:
        for r2 in possible_resistors:
            for r3 in possible_resistors:
                for r4 in possible_resistors:
                    if k % 1000 == 0:
                        print ("Testing resistor combination %d / %d" % (k, k_max))

                    k += 1

                    # Compute 16 code points
                    points = []

                    for i in range(5):
                        points += [ r / (r + parallel(c)) for c in itertools.combinations([r1,r2,r3,r4], i) ]

                    # Compute minimum distance
                    min_dist = math.inf

                    for i, p1 in enumerate(points):
                        for j, p2 in enumerate(points):
                            if i != j:
                                dist = abs(p1 - p2)
                                if dist < min_dist:
                                    min_dist = dist

                    if min_dist > max_min_dist:
                        max_min_dist = min_dist
                        best_configuration = (r1, r2, r3, r4)
                        best_points = points

    # Error calculations
    # Maximum deviation from codepoint by tolerance
    r1,r2,r3,r4 = best_configuration

    max_deviation = 0.

    for e,e1,e2,e3,e4 in itertools.product([1. - tolerance, 1., 1. + tolerance], repeat=5):
        rr = r * e
        r1r = r1 * e1
        r2r = r2 * e2
        r3r = r3 * e3
        r4r = r4 * e4

        # Compute 16 code points
        r_points = []

        for i in range(5):
            r_points += [ rr / (rr + parallel(c)) for c in itertools.combinations([r1r,r2r,r3r,r4r], i) ]

        # For each codepoint compute its deviation from the nominal one.
        # ... assuming itertools.combinations is deterministic
        for i in range(len(points)):
            p1 = best_points[i]
            p2 = r_points[i]

            deviation = abs(p1 - p2)

            max_deviation = max(max_deviation, deviation)


    print()

    print("Best configuration: R = %f, R1 = %f, R2 = %f, R3 = %f, R4 = %f" % (r,r1,r2,r3,r4))

    print("Minimum distance: %f, %f bits required." % (max_min_dist, -math.log2(max_min_dist)))
    print("Maximum deviation respecting tolerance: %f => %s." % (max_deviation,
        "ok" if max_deviation < max_min_dist / 2 else "TOO LARGE"))

    i_max = U / (r + parallel(r1, r2, r3, r4))
    i_min = U / (r + max(best_configuration))
    print("Minimum current >0: %f, maximum current: %f, maximum power dissipation: %f" % (i_min, i_max, i_max * U))

    print()
    print("Corresponding code points (R4, R3, R2, R1):")
    points = []
    for s4,s3,s2,s1 in itertools.product([0,1], repeat=4):
        c = []
        if s4: c.append(r4)
        if s3: c.append(r3)
        if s2: c.append(r2)
        if s1: c.append(r1)

        v = r / (r + parallel(c))
        points.append(v)
        print("  %d%d%d%d: %f" % (s4,s3,s2,s1,v))

    print("8 bit table: %s" % (', '.join([ str(round(v * 255)) for v in points ])))

if __name__ == '__main__':
    main()
