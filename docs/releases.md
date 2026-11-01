# MacSweep Release and Automatic Update Guide

MacSweep is distributed through `opencorex-org/macsweep` as an open-source, ad-hoc-signed macOS application. Published releases include a DMG for users and a Sparkle-signed ZIP plus appcast for updates. No paid Apple Developer account or App Store submission is required.

## Release artifacts

Every stable release publishes:

- `MacSweep-<version>.dmg` — drag-to-Applications installer.
- `MacSweep-<version>.zip` — application update consumed by Sparkle.
- `appcast.xml` — Sparkle update metadata and EdDSA signature.
- `SHA256SUMS.txt` — SHA-256 checksums for the DMG and update ZIP.

Installed copies read the stable feed at:

`https://github.com/opencorex-org/macsweep/releases/latest/download/appcast.xml`

## Required GitHub Actions secrets

Configure these repository secrets before pushing a release tag:

- `SPARKLE_PUBLIC_KEY` — base64 public EdDSA key printed by Sparkle `generate_keys`.
- `SPARKLE_PRIVATE_KEY` — private EdDSA key exported by `generate_keys -x`.

Never commit private keys, certificates, or passwords.

## One-time Sparkle key setup

Use the `generate_keys` executable included with the pinned Sparkle release:

```bash
generate_keys
generate_keys -x sparkle-private-key
```

Store the printed public key as `SPARKLE_PUBLIC_KEY`. Store the contents of `sparkle-private-key` as `SPARKLE_PRIVATE_KEY`, then securely remove the exported local file after confirming the secrets are configured.

The same Sparkle key must be retained for future releases. Losing it can prevent installed copies from accepting updates.

## Version policy

- Git tags use semantic versions: `vMAJOR.MINOR.PATCH`.
- `MARKETING_VERSION` must exactly match the tag without its `v` prefix.
- `CURRENT_PROJECT_VERSION` must increase for every published build, including rebuilds of the same marketing version.
- Stable releases are created only from the protected `main` branch.

## Publishing a release

1. Update `MARKETING_VERSION`, `CURRENT_PROJECT_VERSION`, `CHANGELOG.md`, and `RELEASE_NOTES.md` in the release pull request.
2. Merge the completed and reviewed pull request into `main`.
3. The Verify workflow builds and tests the exact merge commit.
4. After verification succeeds, the Auto Release Tag workflow validates the release metadata and creates the matching annotated `vMAJOR.MINOR.PATCH` tag if it does not already exist.
5. The tag starts the Release workflow, which builds, ad-hoc signs, verifies, packages, signs the Sparkle update, generates the appcast, and publishes the GitHub Release.
6. Download the published DMG and verify installation on a clean Mac account.

The tag step is idempotent: ordinary merges that keep the current version do not create another release. The workflow can also be started manually from GitHub Actions after correcting a configuration problem.

The workflow fails before publication if a required Sparkle secret is absent or any build, ad-hoc signature, packaging, or appcast step fails.

## Future automatic updates

For `v1.0.1` and later, repeat the version and release-notes update process; the tag and GitHub Release are created automatically after the merge passes verification. Sparkle checks the stable appcast automatically, compares the incrementing bundle version, verifies the EdDSA update signature, then offers or installs the update according to the user’s Settings choices.
