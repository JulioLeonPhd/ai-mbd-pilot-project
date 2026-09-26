---
status: accepted
---

# Adopt pilot ADC storage and sample integrity rules

On 2026-09-26, Julio approved preserving raw `int16` ADC samples on disk and
converting them to floating point when loaded for MATLAB processing. ADC
voltage denotes quantized voltage at the ADC input after any receiver gain or
attenuation represented by the stimulus or frontend model. A declared
volts-per-LSB conversion reconstructs voltage from codes and does not silently
undo receiver gain. All 64 channels use the same ideal receiver gain and
conversion scale; channel-mismatch estimation, correction, and calibration
algorithms are outside pilot scope. The same raw vectors may be used by a
future Simulink path, without prescribing its arithmetic data type.
Retaining quantized capture lets MATLAB and a future Simulink path use the same
source data; a declared scale gives it physical meaning without silently
applying or undoing modeled receiver gain.

For the pilot, ADC samples form a correctly sampled, contiguous timeline.
Producers and readers must reject missing or discontinuous ticks without
inferring or filling gaps; frame, pulse, and PRF boundaries do not reset DDC
state or discard elapsed samples. This rule does not specify the signal values
used for transmit blanking. It narrows no broader storage support for ordered
or windowed slabs, and historical unit-only fixtures remain outside the pilot
ADC continuity scope.
Rejecting gaps preserves elapsed-time and DDC-state meaning instead of
fabricating samples. Broader ordered or windowed slab storage remains useful
outside the stricter pilot stream rule.

The future generator clips or saturates samples at representable ADC limits,
reports clipped sample counts per channel, and never rescales a scenario to
fit. Normal scenarios are checked for headroom; intentional overload scenarios
are separate so scenario comparison does not hide overload. Numerical
conversion scale, reference impedance, receiver gain,
full-scale convention, noise convention and injection point, and quantizer
rounding remain open for evidence and review. AGC/STC effects may be
represented in future stimulus or frontend work; no controller design,
clutter-scope expansion, or DUT-boundary change is approved. This supplements
[ADR 0013](0013-adopt-150msps-50mhz-if-and-direct-adc-stimulus.md) without
changing its ADC rate, IF, waveform, or DDC decisions. Independent semantic
review passed on 2026-09-26 with no unresolved findings; these approved rules
are not implementation-status claims.
