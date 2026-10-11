---
status: accepted
---
# Adopt human-led module design and Simulink staging

On 2026-09-26, Julio confirmed human-led design: agents may
investigate and implement routine work within approved decisions; Julio
retains architecture authority. Default: namespaced MATLAB functions with explicit
configuration and state structs, including separate DDC and
commanded-azimuth beamforming modules; consider classes only after
demonstrated simplification or invariant benefit reviewed. Test modules
directly through public interfaces: controlled inputs, independent
expectations mapped to applicable requirement IDs. Keep fixture and
integration tests where useful; requirement verification distinct from
structural code coverage; metrics and thresholds remain undecided.
DDC: allow variable MATLAB frame lengths; carry mixer count, FIR
history, and decimation phase across calls. Simulink: fixed dimensions
per configured model; validate supported configuration before run; keep
configuration fixed during run. Test channel count configurable;
64 default. Supports focused tests and reproducible executions.

Continuous-state-across-calls clause records former DDC baseline;
superseded for future DDC execution by [ADR 0022](0022-adopt-independent-pri-ddc-processing.md):
MATLAB processes complete physical PRIs, fresh local state per call.
Fixed-dimension Simulink direction and configurable test channel count remain;
exact Simulink topology and execution mechanism still open.

Preserve [ADR 0003's](0003-stage-floating-point-fixed-point-simulink.md)
order: floating-point MATLAB reference, fixed-point design and analysis, then
Simulink. Simulink stage: behavioral model first,
with approved algorithms, interfaces, fixed dimensions, meaningful timing, and
buffering; need not be cycle-accurate. Separate, more
implementation-oriented Simulink model may follow. Models need not mirror
MATLAB functions one-for-one. Refines ADR 0003: defines two Simulink
representations without removing fixed-point stage. Frame dimensions
fixed per configured model; sample-based versus frame-based execution
still open. Separate behavioral view from hardware-oriented detail:
algorithms, interfaces, meaningful timing available for human review before
implementation structure introduced. HDL remains deferred under
[ADR 0008](0008-defer-hdl-generation-and-cosimulation.md). Independent semantic
review passed on 2026-09-26 with no unresolved findings; record does not
claim implementation or full
requirements coverage.
