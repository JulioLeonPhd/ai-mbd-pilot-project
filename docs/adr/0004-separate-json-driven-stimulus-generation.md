---
status: accepted
---

# Keep scenario-driven stimulus generation outside the DUT

An external MATLAB signal generator will read a JSON target scenario and save
the resulting stimulus and associated data as MAT-file test vectors. The DUT
therefore consumes repeatable digitized inputs while scenario authoring and
waveform generation remain independently testable.
