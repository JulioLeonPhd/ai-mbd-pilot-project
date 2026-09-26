---
status: accepted
---

# Adopt DSP responsibilities and retain ambiguity requirements

On 2026-09-26, Julio confirmed separate DSP responsibilities for range
processing, combined pulse accumulation and range-migration handling, Doppler
processing, CFAR, multi-PRF fusion, clustering, range-ambiguity handling,
Doppler unfolding, elevation estimation, and detection reporting. DDC and
commanded-azimuth beamforming remain separate. This list defines
responsibility boundaries, not a complete processing sequence. Preserve the
accepted post-CFAR 3-of-5 fusion before clustering. Detection reporting
follows clustering; file I/O and evidence handling remain outside production
processing.
Keeping these responsibilities explicit supports direct module testing and
review without imposing an unapproved end-to-end ordering.

The initial pulse-accumulation/range-migration baseline prepares ensembles
without range-migration compensation; measure it against applicable
requirements to establish a baseline before adding compensation assumptions.
Any ideal, truth-assisted compensation is a test or oracle
benchmark only, never a production DUT input. The module name, interface,
dependencies, possible later compensation, and its sequence relative to
Doppler unfolding remain open. Corner turning means data transposition or
reordering, not matrix inversion; it is distinct from pulse accumulation.
Buffer ownership, physical data movement, per-PRI buffering, and the specific
1-D FFT or Doppler-bank method are unresolved.

Elevation estimation receives four complex values for selected range-Doppler
candidates and returns angle with quality or validity information. V1 uses
commanded azimuth, consistent with [ADR
0017](0017-adopt-v1-commanded-look-receive-processing-and-g2-schedule.md), and
does not claim sub-beam azimuth estimation. This clarifies the estimator
interface in ADR 0017 without changing its 64-to-four commanded-look seam.
Detection reporting after clustering resolves that placement left open by ADR
0005; other processing orderings from ADR 0005 remain open. Range-ambiguity
handling is a responsibility, but its algorithm and scope remain open. Retain
the 100 km requirement while studying multi-PRF resolution and waveform
diversity. Any reduction in coverage requires Julio's explicit requirement
decision; waveform diversity is a study candidate, not an approved method.
These decisions clarify module responsibilities without superseding the
100 km requirement in
[ADR 0009](0009-radar-mvp-acceptance-and-ambiguity-requirements.md) or the
commanded-look seam in ADR 0017. Independent semantic review passed on
2026-09-26 with no unresolved findings.
