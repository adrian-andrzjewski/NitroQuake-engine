"""Exercise the production DOS CPU guard with DOSBox-X's normal CPU core.

Explicit optional emulator test; no benchmark checkout or game data required.
Unsupported cases deliberately have neither CWSDPMI nor PAK files. Supported
cases reach the engine's DOS system report after loading CWSDPMI, then exit
because no game data is staged (the engine's existing exit status is zero).
"""
from pathlib import Path
import argparse
import hashlib
import json
import os
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
MINIMUM = 'Minimum: Intel 486DX-compatible CPU with a 387-compatible x87 FPU.'
FPU_MISSING = 'usable 387-compatible x87 FPU missing'
CASES = [
    ('8086', 'false', 'missing 32-bit 386 CPU instructions'),
    ('80186_prefetch', 'false', 'missing 32-bit 386 CPU instructions'),
    ('286', 'false', 'missing 32-bit 386 CPU instructions'),
    ('386', '387', 'missing 486 CPU instruction set'),
    ('486old', 'false', FPU_MISSING),
    ('486', 'false', FPU_MISSING),
    ('486old', '8087', FPU_MISSING),
    ('486old', '287', FPU_MISSING),
    ('486old', '387', None),  # Pre-CPUID 486.
    ('486', '387', None),
    ('pentium', '387', None),
]


def fixtures(djasm, work):
    """Use the production fragment to verify machine-state handoff and #NM avoidance."""
    fragment = (ROOT / 'tools/dos-cpu-guard.asm').read_text(encoding='ascii').replace('        .start', '')
    registers = dict(eax=0x12345678, ebx=0x23456789, ecx=0x3456789a,
                     edx=0x456789ab, esi=0x56789abc, edi=0x6789abcd, ebp=0x789abcde)
    for name in ('state-0', 'state-2', 'em', 'ts'):
        case = work / name
        case.mkdir(parents=True)
        setup = '.org 0x100\n.start\npush cs\npop ds\n'
        if name in ('em', 'ts'):
            setup += 'smsw ax\nor ax, ' + ('4' if name == 'em' else '8') + '\nlmsw ax\n'
            setup += 'std\n'  # Rejection must normalize DF before DOS output.
            continuation = 'nq_loader_start:\nmov ax, 0x4c02\nint 0x21\n'
        else:
            setup += f'sub sp, {name[-1]}\nmov [saved_sp], sp\nmov [saved_es], es\n'
            setup += ''.join(f'mov {reg}, {value}\n' for reg, value in registers.items())
            setup += 'std\nstc\npushfd\npopd [saved_flags]\n'
            continuation = 'nq_loader_start:\npushfd\npopd [actual_flags]\ncld\n'
            for reg, value in registers.items():
                continuation += f'cmp {reg}, {value}\nje @f1\njmpl failed\n@f1:\n'
            continuation += '''cmp sp, [saved_sp]
je @f1
jmpl failed
@f1:
mov ax, ds
push cs
pop dx
cmp ax, dx
je @f1
jmpl failed
@f1:
mov ax, es
cmp ax, [saved_es]
je @f1
jmpl failed
@f1:
mov eax, [saved_flags]
cmp eax, [actual_flags]
je @f1
jmpl failed
@f1:
mov dx, passed
mov ah, 9
int 0x21
mov ax, 0x4c00
int 0x21
failed:
mov ax, 0x4c02
int 0x21
passed:
.db "CPU guard state preserved.\r\n$"
saved_sp:
.dw 0
saved_es:
.dw 0
saved_flags:
.dd 0
actual_flags:
.dd 0
'''
        (case / 'fixture.asm').write_text(setup + 'jmpl nq_cpu_guard\n' + continuation + fragment, encoding='ascii')
        subprocess.run([str(djasm.resolve()), 'fixture.asm', 'fixture.com', 'fixture.map'],
                       cwd=case, check=True, capture_output=True, text=True)
        yield name, case / 'fixture.com'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--executable', type=Path, required=True)
    parser.add_argument('--dosbox', type=Path, required=True)
    parser.add_argument('--djasm', type=Path, help='Also test register/FLAGS preservation and CR0.EM/TS rejection')
    parser.add_argument('--timeout', type=int, default=30)
    args = parser.parse_args()
    executable = args.executable.resolve()
    dosbox = args.dosbox.resolve()
    work = Path(tempfile.mkdtemp(prefix='cpu-guard-dos-', dir=ROOT / 'out'))
    results = []
    cases = [(cpu + '-' + fpu, cpu, fpu, missing, executable, 'quake.exe') for cpu, fpu, missing in CASES]
    if args.djasm:
        cases += [(name, '486old', '387', FPU_MISSING
                   if name in ('em', 'ts') else None, path, 'fixture.com')
                  for name, path in fixtures(args.djasm, work / 'fixtures')]
    for name, cpu, fpu, missing, binary, command in cases:
        case = work / name
        case.mkdir()
        shutil.copyfile(binary, case / command)
        fixture = command.endswith('.com')
        if missing is None and not fixture:
            shutil.copyfile(ROOT / 'src/cwsdpmi.exe', case / 'cwsdpmi.exe')
        # Separate batch labels check ERRORLEVEL exactly (IF checks >=).
        (case / 'run.bat').write_text(
            f'@echo off\n{command} -dedicated -nosound -nojoy -nomouse > result.txt\n'
            'if errorlevel 2 goto bad\n'
            'if errorlevel 1 goto one\n'
            'echo 0> status.txt\ngoto done\n'
            ':one\necho 1> status.txt\ngoto done\n'
            ':bad\necho BAD> status.txt\n:done\nexit\n', encoding='ascii')
        config = case / 'dosbox.conf'
        config.write_text(f'''[sdl]
fullscreen=false
output=surface
autolock=false
waitonerror=false
[dosbox]
machine=svga_s3
memsize=32
[cpu]
core=normal
cputype={cpu}
fpu={fpu}
cycles=fixed 100000
[mixer]
nosound=true
[dos]
xms=true
ems=false
umb=false
[autoexec]
mount c "{case}"
c:
run.bat
''', encoding='ascii')
        with (case / 'emulator.log').open('w') as log:
            environment = dict(os.environ, SDL_VIDEODRIVER='dummy', SDL_AUDIODRIVER='dummy')
            process = subprocess.run([str(dosbox), '-conf', str(config), '-exit', '-fastlaunch'],
                cwd=dosbox.parent, stdout=log, stderr=subprocess.STDOUT,
                timeout=args.timeout, env=environment,
                creationflags=getattr(subprocess, 'CREATE_NO_WINDOW', 0))
        output = (case / 'result.txt').read_text(encoding='ascii')
        status = (case / 'status.txt').read_text(encoding='ascii').strip()
        assert process.returncode == 0 and status == ('1' if missing else '0'), (cpu, fpu, status, output)
        if missing:
            assert missing in output and MINIMUM in output, (cpu, fpu, output)
            assert all(len(line) <= 80 for line in output.splitlines()), output
            assert 'Build ' not in output and 'Load error' not in output, output
        else:
            if fixture:
                assert output.strip() == 'CPU guard state preserved.', output
            else:
                assert 'NitroQuake v' in output and 'Build ' in output, output
                assert 'FPU startup check: passed' in output and 'Video: disabled (dedicated)' in output, output
            assert MINIMUM not in output, output
        results.append(dict(case=name, cpu=cpu, fpu=fpu, passed=True, dosExitCode=int(status),
                            diagnostic=missing or 'protected-mode engine system report'))
        print(f'PASS: {name}', flush=True)
    (work / 'results.json').write_text(json.dumps(dict(passed=True,
        executable=str(executable), executableSha256=hashlib.sha256(executable.read_bytes()).hexdigest(),
        emulator=str(dosbox), emulatorSha256=hashlib.sha256(dosbox.read_bytes()).hexdigest(),
        tests=results), indent=2) + '\n', encoding='ascii')
    print('CPU guard DOS matrix PASS: ' + str(work))


if __name__ == '__main__':
    main()
