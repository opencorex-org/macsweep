# MacSweep Release and Automatic Update Guide

MacSweep is distributed through `opencorex-org/macsweep` as a Developer ID signed and Apple-notarized macOS application. Published releases include a DMG for users and a signed ZIP plus appcast for Sparkle updates.

## Release artifacts

Every stable release publishes:

- `MacSweep-<version>.dmg` — notarized drag-to-Applications installer.
- `MacSweep-<version>.zip` — notarized application update consumed by Sparkle.
- `appcast.xml` — Sparkle update metadata and EdDSA signature.
- `SHA256SUMS.txt` — SHA-256 checksums for the DMG and update ZIP.

Installed copies read the stable feed at:

`https://github.com/opencorex-org/macsweep/releases/latest/download/appcast.xml`

## Required GitHub Actions secrets

Configure these repository secrets before pushing a release tag:

- `MACOS_CERTIFICATE` — base64-encoded Developer ID Application `.p12` file.
- `MACOS_CERTIFICATE_PASSWORD` — password used when exporting the `.p12` file.
- `KEYCHAIN_PASSWORD` — a strong temporary CI keychain password.
- `APPLE_API_KEY_ID` — App Store Connect API key ID for notarization.
- `APPLE_API_ISSUER_ID` — App Store Connect issuer ID.
- `APPLE_API_PRIVATE_KEY` — complete contents of the matching `AuthKey_<ID>.p8` file.
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
- GitHub Actions assigns `CURRENT_PROJECT_VERSION` from the workflow run number, so every published build has a newer update version.
- Stable releases are created only from the protected `main` branch.

## Publishing a release

1. Merge the completed and reviewed `dev` changes into `main`.
2. Confirm the Verify workflow passes on `main`.
3. Update `MARKETING_VERSION`, `CHANGELOG.md`, and `RELEASE_NOTES.md`. GitHub Actions supplies the build number.
4. Create an annotated tag, for example `git tag -a v1.0.0 -m "Release v1.0.0"`.
5. Push the tag to the official repository.
6. The Release workflow builds, signs, notarizes, staples, verifies, packages, signs the Sparkle update, generates the appcast, uploads a draft release, and publishes it only after every asset upload succeeds.
7. Download the published DMG and verify installation on a clean Mac account.

The workflow fails before publication if a required secret is absent or any build, signature, notarization, Gatekeeper, packaging, or appcast step fails.

## Future automatic updates

For `v1.0.1` and later, repeat the same version and tag process. Sparkle checks the stable appcast automatically, compares the incrementing bundle version, verifies the EdDSA update signature and Developer ID identity, then offers or installs the update according to the user’s Settings choices.
