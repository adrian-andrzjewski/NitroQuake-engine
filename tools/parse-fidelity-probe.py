import re
import subprocess
import sys

path = sys.argv[1] if len(sys.argv) > 1 else 'out/fidelity-probe-host.exe'
result = subprocess.run([path], capture_output=True, text=True)
text = result.stdout
print(text)

ns = {}
for line in text.splitlines():
    # "fidelity <name> [fistp32|fist16] <n> ops <s> sec <ns> ns/op checksum <c>"
    # The label alternation must be explicit, not a greedy \S+, or it swallows
    # the iteration count and the whole line fails to match.
    m = re.match(
        r'fidelity\s+(\S+)(?:\s+(fistp32|fist16))?\s+(\d+)\s+ops\s+([0-9.]+)\s+sec\s+([0-9.]+)\s+ns/op',
        line)
    if not m:
        continue
    name = m.group(1)
    sub = m.group(2)
    value = float(m.group(5))
    key = sub if sub else name
    ns[key] = value

print('=== separations ===')
checks = [
    ('x87chain', 'fistp32', 3.0, 'x87 chain vs one FISTPL store'),
    ('fistp32', 'fist16', 1.05, 'FISTPL vs 16-bit FIST'),
    ('l1-24576', 'l1-4096', 1.05, 'L1 capacity cliff'),
    ('alias-0', 'alias-64', 1.05, 'cache-set aliasing'),
]
passed = 0
for num, den, gate, label in checks:
    if num not in ns or den not in ns or ns[den] <= 0:
        print('  %-28s n/a (missing probe)' % label)
        continue
    ratio = ns[num] / ns[den]
    ok = ratio >= gate
    passed += 1 if ok else 0
    print('  %-28s %6.3fx  gate %.2f  %s' % (label, ratio, gate, 'PASS' if ok else 'FAIL'))
print('  RESULT: %d/%d' % (passed, len(checks)))
