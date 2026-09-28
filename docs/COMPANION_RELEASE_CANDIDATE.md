# agents-sdk 1.1.0 companion release candidate

Status: candidate, not published. No release tag created by this preparation.

## Runtime evidence

Validated locally with the published macOS x64 Kujo 1.6.0 binary:
`930e0da1fec2562f6990d1226a479330640c8c78eb4c36c148cee3f950b29a47`.
Its source is `44af277848173664f72ca85f2a1b3b98d634ecdd`.
This does not certify other platforms; hosted candidate checks must be inspected separately.

Local canonical offline gate: 41 checks, zero failures. Context contracts, 20 paired repetitions and 14 VM/interpreter executions passed; context token ratchet passed. Ability remains pinned to 4aa354da8d02b027c459f692f69b523f96e97056. Existing local-first APIs remain stable; controlled interoperability handoffs are experimental alpha, and Dispatch retains replay/admission authority.

## Release completion checklist

- Inspect hosted checks for the exact candidate commit.
- Verify clean source-archive consumption and package version consistency.
- Review the candidate changelog and turn its candidate heading into a release date only when publishing.
- Create an immutable tag at the tested final source; do not move an existing tag.
- Publish the GitHub source release and reconcile the Kennel index if this package is distributed there.
- Retain experimental contract labels. Do not publish the separate participant SDK packages.
