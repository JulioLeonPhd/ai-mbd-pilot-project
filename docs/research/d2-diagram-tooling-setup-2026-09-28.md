# D2 setup facts for a macOS pilot

Checked 2026-09-28. The latest D2 release shown by the official release page is
`v0.9.0` (released 2026-09-07). Recheck the release page before a later pilot;
“latest” changes over time. [D2 releases](https://github.com/d2lang/d2/releases)

## Official installation options

- **Homebrew:** `brew install d2`. This is the simplest macOS option, but the
  formula tracks package-manager state and does not by itself pin a reproducible
  version. D2 binaries built with Go 1.27 require macOS 13 Ventura or newer.
  [D2 install guide](https://github.com/d2lang/d2/blob/master/docs/INSTALL.md)
- **Pinned standalone release:** D2 publishes OS/architecture archives. The
  documented filename pattern is
  `d2-v<VERSION>-macos-<ARCH>.tar.gz`; set `VERSION=v0.9.0` and choose the
  archive matching the Mac (`arm64` or `amd64`). Releases from the current
  release workflow include `SHA256SUMS` and GitHub artifact attestations; the
  install guide also says the installer checks the GitHub-provided SHA-256
  digest when available. A versioned archive plus checksum/provenance check is
  the more reproducible pilot input. [D2 install guide](https://github.com/d2lang/d2/blob/master/docs/INSTALL.md),
  [v0.9.0 release](https://github.com/d2lang/d2/releases/tag/v0.9.0)
- **Homebrew HEAD or source via Go:** documented alternatives, but they build
  current source and are less suitable for a fixed-version comparison. The
  source install requires Go 1.27 or newer. [D2 install guide](https://github.com/d2lang/d2/blob/master/docs/INSTALL.md)
- **Install script:** upstream supports `--dry-run` and a `--version` option.
  It is convenient, but a versioned release archive or direct package-manager
  install makes the selected installation input clearer. Do not run the
  unpinned `curl | sh` form for a reproducible pilot. [D2 install guide](https://github.com/d2lang/d2/blob/master/docs/INSTALL.md)

Example pinned archive check for Apple Silicon (substitute `amd64` for Intel):

```sh
set -eu
pilot_tmp="$(mktemp -d "${TMPDIR:-/tmp}/d2-pilot.XXXXXX")"
pilot_prefix="${pilot_tmp}/install"
pilot_version=v0.9.0
pilot_arch=arm64
pilot_asset="d2-${pilot_version}-macos-${pilot_arch}.tar.gz"
pilot_base="https://github.com/d2lang/d2/releases/download/${pilot_version}"
cd "${pilot_tmp}"
curl -fLO "${pilot_base}/${pilot_asset}"
curl -fLO "${pilot_base}/SHA256SUMS"
awk -v asset="${pilot_asset}" \
  '$2 == asset { print; count++ } END { if (count != 1) exit 1 }' \
  SHA256SUMS > selected-checksum.txt
shasum -a 256 -c selected-checksum.txt
tar -xzf "${pilot_asset}"
make -sC "d2-${pilot_version}" install PREFIX="${pilot_prefix}"
"${pilot_prefix}/bin/d2" version
```

The temporary directory keeps the extracted source archive, checksum file, and
installation prefix separate from existing user-level D2 files. Remove that
specific directory after the pilot when it is no longer needed.

The checksum manifest verifies archive bytes against the values published with
the release. GitHub's attestation verification can separately check artifact
provenance, for example:

```sh
gh attestation verify d2-v0.9.0-macos-arm64.tar.gz --repo d2lang/d2
```

The release page marks the `v0.9.0` tag and commit as verified signatures. This
is evidence about the tag/commit; it is distinct from checking a downloaded
archive's checksum or attestation. [v0.9.0 release](https://github.com/d2lang/d2/releases/tag/v0.9.0),
[D2 install guide](https://github.com/d2lang/d2/blob/master/docs/INSTALL.md)

## Runtime and rendering

D2 is distributed as a CLI. Its documented Dagre, ELK, and TALA layout engines
are bundled; Dagre and ELK are native Go ports, and v0.9.0 bundles TALA. The
official docs do not list Java, Graphviz, or PlantUML as prerequisites. For a
plain SVG render, use:

```sh
d2 source.d2 preview.svg
```

The CLI can render `.d2` input to SVG; browser launching is associated with the
optional watch workflow, not this direct render command. Check the installed
CLI with either documented version form, `d2 version` or `d2 --version`, and
record the output with the pilot. [D2 README](https://github.com/d2lang/d2),
[D2 install guide](https://github.com/d2lang/d2/blob/master/docs/INSTALL.md)

## Proposed pilot setup, pending Julio's decision

For a repeatable local comparison, use one explicit release (currently
`v0.9.0`), select the Mac architecture's standalone archive, verify its
published checksum and preferably its GitHub attestation, install into a
temporary task-specific prefix, record the version, then render an isolated
`.d2` file with `d2 source.d2 preview.svg`. Do not add D2 to CI or replace any
current diagram as part of this setup note. Julio decides whether to run the
pilot, which installation channel to standardize on, and whether D2 should be
adopted.

## Sources

- [D2 installation guide](https://github.com/d2lang/d2/blob/master/docs/INSTALL.md)
- [D2 release list](https://github.com/d2lang/d2/releases)
- [D2 v0.9.0 release](https://github.com/d2lang/d2/releases/tag/v0.9.0)
- [D2 repository README](https://github.com/d2lang/d2)
