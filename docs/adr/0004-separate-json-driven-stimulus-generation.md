---
status: accepted
---
# Keep scenario-driven stimulus generation outside the DUT

External MATLAB signal generator reads radar-configuration JSON and
separate target-scenario JSON containing target list, saves
stimulus and associated data as MAT-file test vectors. DUT
consumes repeatable digitized inputs; scenario authoring and
waveform generation remain independently testable. Each MAT-file records
exact radar-configuration and target-scenario versions used,
embeds exact JSON snapshots, records generator revision/version, seed,
and generation parameters.

Generated vectors semantically replayable: acceptance compares sample
arrays and meaningful metadata, without requiring byte-identical MAT-file
serialization or SHA hashes. Routine generated vectors ignored under
`data/testVectors/`; deliberately retained large reference vectors may stay
under `data/retainedTestVectors/` with Git LFS. Small canonical shape
example remains tracked until WP5 provides generation check.

Policy preserves reproducibility when paths or MATLAB serialization
change, avoids repository growth from disposable binary outputs. It
does not select DSP algorithms or processing order.
