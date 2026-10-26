---
status: accepted
---
# Adopt DSP responsibilities and retain ambiguity requirements

2026-09-26: Julio confirmed separate DSP responsibilities: range
processing, combined pulse accumulation and range-migration handling, Doppler
processing, CFAR, multi-PRF fusion, clustering, range-ambiguity handling,
Doppler unfolding, elevation estimation, detection reporting. DDC and
commanded-azimuth beamforming remain separate. List defines
responsibility boundaries, not complete processing sequence. Preserve
accepted post-CFAR 3-of-5 fusion before clustering. Detection reporting
follows clustering; file I/O and evidence handling remain outside production
processing.
Explicit responsibilities support direct module testing and
review without imposing unapproved end-to-end ordering.

Initial pulse-accumulation/range-migration baseline prepares ensembles
without range-migration compensation; measure against applicable
requirements to establish baseline before adding compensation assumptions.
Any ideal, truth-assisted compensation: test or oracle
benchmark only, never production DUT input. Module name, interface,
dependencies, possible later compensation, and sequence relative to
Doppler unfolding remain open. Corner turning means data transposition or
reordering, not matrix inversion; distinct from pulse accumulation.
Buffer ownership, physical data movement, per-PRI buffering, specific
1-D FFT or Doppler-bank method unresolved.

Elevation estimation receives four complex values for selected range-Doppler
candidates; returns angle with quality or validity information. V1 uses
commanded azimuth, consistent with [ADR
0017](0017-adopt-v1-commanded-look-receive-processing-and-g2-schedule.md);
does not claim sub-beam azimuth estimation. Clarifies estimator
interface in ADR 0017 without changing its 64-to-four commanded-look seam.
Detection reporting after clustering resolves placement left open by ADR
0005; other processing orderings from ADR 0005 remain open. Range-ambiguity
handling: responsibility; algorithm and scope remain open. Retain
100 km requirement while studying multi-PRF resolution and waveform
diversity. Any coverage reduction requires Julio's explicit requirement
decision; waveform diversity: study candidate, not approved method.
Decisions clarify module responsibilities without superseding
100 km requirement in
[ADR 0009](0009-radar-mvp-acceptance-and-ambiguity-requirements.md) or
commanded-look seam in ADR 0017. Independent semantic review passed
2026-09-26 with no unresolved findings.
