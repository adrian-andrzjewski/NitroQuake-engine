# Automatic executable and runtime ISA verification

## Strict source-bound proof is integrated into normal builds

The main checkout now runs exact project-source proofs, the portable primary
runtime bundle, relocated executable decoding, source-rebuilt startup mapping
and the maintained provider proof on every audited i486 build. There are no
instruction exemptions, unknown encodings, interior instruction cuts,
continuation-byte skips or relocation-field bypasses. A changed native runtime
member, policy, provider or proof artifact invalidates cached execution.
See [the reproduction guide](../ISA-VERIFICATION.md) for the commands and boundaries.

The accepted release contains 117 project objects and 235 runtime objects.
Its 352 exact object streams and actual relocated executable both contain
169,312 instructions: 169,311 i386 and one i486. Final mapping binds 337 linked
contributions and 1,383 code ranges. The loader and CRT helpers account for
all 1,660 loaded startup bytes and 529 instructions. The provider adds 9,207
instructions and one separately decoded runtime branch variant. Every strict
decoder passes with zero exemptions.

The release is retained in
`out/profile-a8b00f0c85d75566/provider-complete-accepted-artifact-20261008`.
Its executable SHA256 is
`F86F94C5562E5FFFC965EEDBB9B81258522F5BC1D4559143CDD2591EC80AF7C5`;
its build manifest is
`27889D818F0488E5208BC43210214105F88EBE39C03D204C18671ECBBA20C863`.
All 35 accepted assembly modules have identical allocated bytes, section
properties and normalized relocations to the accepted drawing-port release.
Adding verification did not modify their renderer instructions.

## Cached execution and adversarial checks pass

The real cached runner verifies the current policy, final executable, exact
relocated report, startup proof and provider proof. The first cache check
revealed that a `tools/..` repository spelling changed bundle-relative names
in the policy digest. Canonicalizing the repository path fixes that defect;
the path-equivalence regression and fresh real cached check both pass. The
earlier pre-provider proof snapshot is retained separately rather than reused
as current cache evidence.

The final release passes 21 loader binding checks, 22 CRT helper checks and
one exact final-startup mapping plus nine adversarial rejections. Current
encoding tests accept 505 permitted and reject 544 forbidden cases. Boundary
tests pass 43 adversarial checks; runtime identity tests cover 235 inputs and
13 adversarial changes; final mapping has fourteen rejection cases and genuine
linked-executable checks cover nine cases. Windows DJASM selection also rejects
DOS compiler and contaminated environment inputs. The provider suite adds 21
adversarial checks.

`out/strict-drawing-runner-verification-20261008.json` records the real cached
proof. The full assembly profile also passes the normal i486 smoke runner with
the staged, hash-verified provider. Smoke parameters now cover the full shared
selector table, including selectors previously available only to benchmark
and timedemo runners. The forwarding regression passes 1,469 checks, exercising
all eighty selectors in benchmark, timedemo and smoke runners. The strict
benchmark build separately passes 232,914 actual relocated instructions and
the same startup/provider proofs. Its integrated drawing fixture passes
11,648 exact cases, 8,192 continuous calls and 128 guard checks with zero
failures in `out/dos-bench-20261008-033218`; the executed binary and bindings
are retained there. The complete combined benchmark then passes in
`out/dos-bench-20261008-040646`: all 35 selected assembly modules, every
registered correctness fixture, zero failures and final checksum 3755475462.
Its exact executed executable, manifest and linked proof are retained in
that run's `accepted-artifact-snapshot`. The runner verifies the complete
strict executable/startup/provider bindings before launching the emulator.
Renderer conversion and full scenario/stability acceptance
continue separately; these machine-code checks alone do not complete the port.
