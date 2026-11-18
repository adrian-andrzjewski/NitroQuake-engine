"""Build/install the early CPU guard in DJGPP's pinned real-mode MZ loader."""
from pathlib import Path
import argparse
import hashlib
import struct
import subprocess
import tempfile
import zipfile

ARCHIVE_SHA = '80690B6E44FF8BC6C6081FCA1F4FAEBA1591C4490B76EF0EC8B35847BAA5DEEA'
SOURCE_SHA = 'EB3AEDE63C1F01D09F4956FFB95D7145EC7C9BEB52B9E97470CEF47B12AFC035'
FRAGMENT = Path(__file__).with_suffix('.asm')


def primary_source(archive):
    if hashlib.sha256(archive.read_bytes()).hexdigest().upper() != ARCHIVE_SHA:
        raise ValueError('Primary startup archive hash changed.')
    with zipfile.ZipFile(archive) as package:
        source = package.read('src/stub/stub.asm')
    if hashlib.sha256(source).hexdigest().upper() != SOURCE_SHA:
        raise ValueError('Primary loader source hash changed.')
    return source


def guarded_source(source):
    text = source.decode('ascii').replace('\r\n', '\n')
    entry = '\t.start\t\t\t\t; execution begins here'
    end = 'last_generated_byte:\n'
    if text.count(entry) != 1 or text.count(end) != 1:
        raise ValueError('Pinned loader insertion points changed.')
    # Preserve all original instruction offsets (including the intentional
    # TEST/REPNE overlap). The only original-source edits are the entry label
    # and an appended fragment; DJASM resolves the moved BSS and stack labels.
    text = text.replace(entry, 'nq_loader_start:')
    text = text.replace(end, FRAGMENT.read_text(encoding='ascii') + '\n' + end)
    return text.encode('ascii')


def assemble(archive, djasm, output, guarded=True):
    output.mkdir(parents=True, exist_ok=True)
    source = primary_source(archive)
    (output / 'stub.asm').write_bytes(guarded_source(source) if guarded else source)
    subprocess.run([str(djasm.resolve()), 'stub.asm', 'stub.exe', 'stub.map'],
                   cwd=output, check=True, capture_output=True, text=True)
    return (output / 'stub.exe').read_bytes()


def mz_length(blob):
    if len(blob) < 28 or blob[:2] != b'MZ':
        raise ValueError('Expected a complete DJGPP MZ executable.')
    last, pages = struct.unpack_from('<HH', blob, 2)
    length = pages * 512 - (512 - last if last else 0)
    if not 28 <= length <= len(blob):
        raise ValueError('Invalid MZ image size.')
    return length


def loaded_mz(blob):
    size = mz_length(blob)
    fields = struct.unpack_from('<14H', blob)
    return fields, blob[fields[4] * 16:size]


def install(archive, djasm, executable):
    blob = executable.read_bytes()
    length = mz_length(blob)
    # Refuse to replace an unknown/custom stub, or to damage a non-COFF file.
    if blob[length:length + 2] != b'\x4c\x01':
        raise ValueError('The MZ loader is not followed by an i386 COFF image.')
    with tempfile.TemporaryDirectory(prefix='nq-cpu-guard-') as directory:
        work = Path(directory)
        original = assemble(archive, djasm, work / 'original', guarded=False)
        if loaded_mz(blob) != loaded_mz(original):
            raise ValueError('Refusing to replace an unrecognized DJGPP loader.')
        guarded = assemble(archive, djasm, work / 'guarded')
    executable.write_bytes(guarded + blob[length:])
    print(f'Installed pre-DPMI 486/x87 CPU guard ({len(guarded) - length:+d} bytes).')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ('archive', 'djasm', 'executable'):
        parser.add_argument('--' + name, type=Path, required=True)
    args = parser.parse_args()
    install(args.archive, args.djasm, args.executable)


if __name__ == '__main__':
    main()
