# MacSweep Security & Safety Specification
**Organization:** OpenCorex  
**Project:** MacSweep (`opencorex-org/macsweep`)  

---

## Safety Architecture Guidelines

### Protected Paths Policy
MacSweep hardcodes immutable protected system paths in `ProtectedPaths.swift`:
- `/System/`
- `/usr/`
- `/bin/`
- `/sbin/`
- `/var/db/`
- `/private/var/db/`
- `/Library/Apple/`
- `/Library/CoreServices/`
- `~/Library/Keychains/`
- `~/Library/Application Support/com.apple.*/`

### Path Validation & Symlink Protection
1. **Symlink Resolution:** All paths are canonicalized via `URL.resolvingSymlinksInPath()` before evaluation.
2. **Path Traversal Guards:** Candidates attempting to escape the target directory or user sandbox boundaries are strictly rejected.
3. **No Shell Invocations:** Shell commands (`rm -rf`) are strictly prohibited. All deletions are executed via native `FileManager.default.trashItem(at:resultingItemURL:)` or verified native `FileManager` calls.

### Disclosure & Vulnerability Reporting
Security vulnerabilities should be reported directly to OpenCorex security maintainers at `security@opencorex.org` or via GitHub Security Advisories.
