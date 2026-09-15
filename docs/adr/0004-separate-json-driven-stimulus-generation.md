---
status: accepted
---

# Keep scenario-driven stimulus generation outside the DUT

An external MATLAB signal generator will read a radar-configuration JSON and a
separate target-scenario JSON containing the target list, then save
the resulting stimulus and associated data as MAT-file test vectors. The DUT
therefore consumes repeatable digitized inputs while scenario authoring and
waveform generation remain independently testable. Each MAT-file records the
exact radar-configuration and target-scenario versions used to produce it,
embeds the exact JSON snapshots, and records generator revision/version, seed,
and generation parameters.

Generated vectors are semantically replayable: acceptance compares sample
arrays and meaningful metadata, without requiring byte-identical MAT-file
serialization or SHA hashes. Routine generated vectors are ignored under
`data/testVectors/`; deliberately retained large reference vectors may be kept
under `data/retainedTestVectors/` with Git LFS. The small canonical shape
example remains tracked until WP5 provides a generation check.

This policy preserves reproducibility when paths or MATLAB serialization
change, while avoiding repository growth from disposable binary outputs. It
does not select DSP algorithms or processing order.
