# dependency-auditor — worked output example and per-ecosystem signals

Maintainer-facing illustration. NOT read by dispatched agents — the schema and
one example line stay in `agents/dependency-auditor.md`; the multi-section
worked example and ecosystem signal lists live here. The CVE entries below are
illustrative report shapes, not live claims about any project.

## Worked output example

```
## Dependency Audit — [date]

Manifest(s) audited: [list]

### CRITICAL — Security advisories
- `package.json` — `lodash@4.17.15` — CVE-2021-23337 (prototype pollution). Remediate to >= 4.17.21.
- `requirements.txt` — `pyyaml==5.3` — CVE-2020-14343 (arbitrary code exec). Remediate to >= 5.4.

### MAJOR — Deprecated / unmaintained
- `package.json` — `request@2.88.2` — deprecated by maintainer 2020-02-11; replace with `node-fetch`, `axios`, or native `fetch`.
- `requirements.txt` — `nose==1.3.7` — unmaintained since 2015; migrate to `pytest`.

### MAJOR — License conflict
- `package.json` — project license: MIT — `some-gpl-dep@2.1.0` is GPL-3.0. Requires legal review before release.

### MINOR — Unused
- `package.json` — `moment@2.29.4` — declared, zero references in `src/`. Candidate for removal.

### MINOR — Version drift
- `package.json` — `react@17.0.2` — installed; latest stable is 19.x. Two majors behind.

### PASS
- 47 dependencies audited
- 0 critical security advisories blocking release

### SUMMARY
2 critical, 3 major, 2 minor.
```

## Per-ecosystem deprecation signals (long form)

- npm: `"deprecated"` field in lockfile snapshots
- PyPI: well-known deprecations (e.g. `nose`, `mox`, `pep8` → `pycodestyle`, `python-dateutil 1.x`)
- Cargo: yanked crates noted in lockfile
- Maven/Gradle: `<deprecated>true</deprecated>` markers

## License-conflict examples (long form)

- GPL/AGPL dependencies in non-GPL projects
- BSD-3-Clause-Clear when the project ships under MIT
- "UNLICENSED" or missing license fields in production dependencies
