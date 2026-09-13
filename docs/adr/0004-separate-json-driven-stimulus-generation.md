---
status: accepted
---

# Keep scenario-driven stimulus generation outside the DUT

An external MATLAB signal generator will read a radar-configuration JSON and a
separate target-scenario JSON containing the target list, then save
the resulting stimulus and associated data as MAT-file test vectors. The DUT
therefore consumes repeatable digitized inputs while scenario authoring and
waveform generation remain independently testable. Each MAT-file records the
exact radar-configuration and target-scenario versions used to produce it.
