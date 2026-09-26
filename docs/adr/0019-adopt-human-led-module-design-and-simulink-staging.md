---
status: accepted
---

# Adopt human-led module design and Simulink staging

On 2026-09-26, Julio confirmed a human-led design in which agents may
investigate and implement routine work within approved decisions, while Julio
retains architecture authority. Use namespaced MATLAB functions with explicit
configuration and state structs as the default, including separate DDC and
commanded-azimuth beamforming modules; consider classes only when a
demonstrated simplification or invariant benefit is reviewed. Test modules
directly through public interfaces with controlled inputs and independent
expectations mapped to applicable requirement IDs. Keep fixture and
integration tests where useful; requirement verification is distinct from
structural code coverage, whose metrics and thresholds remain undecided.
For DDC, allow variable frame lengths in MATLAB while carrying mixer count, FIR
history, and decimation phase across calls. In Simulink, use fixed dimensions
per configured model and validate supported configuration before a run; keep
the configuration fixed during that run. Channel count is configurable for
tests, with 64 as the default. This supports focused test cases while keeping
each execution reproducible.

Preserve [ADR 0003's](0003-stage-floating-point-fixed-point-simulink.md)
floating-point MATLAB reference, fixed-point design and analysis, then
Simulink order. Within the Simulink stage, build a behavioral model first,
with approved algorithms, interfaces, fixed dimensions, meaningful timing, and
buffering; it need not be cycle-accurate. A separate, more
implementation-oriented Simulink model may follow. The models need not mirror
MATLAB functions one-for-one. This refines ADR 0003 by defining two Simulink
representations without removing its fixed-point stage. Frame dimensions are
fixed per configured model, but sample-based versus frame-based execution is
still open. Separating the behavioral view from hardware-oriented detail keeps
algorithms, interfaces, and meaningful timing available for human review before
implementation structure is introduced. HDL remains deferred under
[ADR 0008](0008-defer-hdl-generation-and-cosimulation.md). Independent semantic
review passed on 2026-09-26 with no unresolved findings; this record does not
claim implementation or full
requirements coverage.
