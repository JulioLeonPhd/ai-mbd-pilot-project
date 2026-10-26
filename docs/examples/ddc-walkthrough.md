# DDC walkthrough

This walkthrough follows one complete physical pulse repetition interval (PRI)
through the approved per-PRI digital down-converter (DDC). It explains the
sample path, rates, units, startup behavior, amplitude convention, and limits of
the evidence. The executable example uses the public API
`[output, metadata] = radardemo.ddc.processFrame(adcPriSamples, design)`;
production filter and mixer algorithms remain behind that API.

Each call starts with a local sample index of zero and fresh mixer, FIR, and
decimation state. The caller selects one PRI, converts stored ADC samples to
finite real `double`, and retains the PRI's global identity and timeline.
Transition gaps remain on that timeline and are not DDC calls. See the accepted
[per-PRI contract and timing decisions](../adr/0022-adopt-independent-pri-ddc-processing.md).

The diagram is the processing chain for one channel. Rates are samples per
second; array dimensions are sample counts. It includes the final factor-two
output compensation.

![One-PRI DDC sample path, rate changes, and final factor-two amplitude compensation](assets/ddc-algorithm.svg)

## Run the example

Requirements: MATLAB R2025a or newer and Signal Processing Toolbox (`fir1` and
`kaiser`). The `.m` file uses plain-text Live Script markup and can run in the
Live Editor or from the command line. It starts with `clc`, `close`, and
`clear`: these clear the command window, close the current figure, and clear
the workspace. From the repository root:

```matlab
addpath("src")
addpath("examples")
run("examples/runDdcWalkthrough.m")
```

The script creates a deterministic, real, quantized ADC record with one
channel and 88,236 samples. The desired signal is a 5 MHz bandwidth chirp
swept linearly from 47.5 to 52.5 MHz around 50 MHz, with 18,000-count peak
amplitude. Its sweep duration is `N/Fs = 588.24 microseconds`; the 52.5 MHz
endpoint is at the exclusive PRI boundary, so the last acquired sample is
approximately 52.499943333 MHz. An undesired 70 MHz interference probe has
3,500-count peak amplitude. Before quantization, the script adds zero-mean
Gaussian noise with 100 ADC-count RMS, using a local `mt19937ar` stream with
seed 17. This is small beside the desired 18,000-count peak and makes
runs reproducible without changing MATLAB's global random state. The script
then rounds the sum to `int16` and converts the PRI to `double` for the DDC.
These are synthetic counts, not calibrated volts. The noise is not a calibrated
receiver-noise or hardware model, and the example makes no SNR estimate. The
PRI begins at ADC tick zero and its length is divisible by the combined
decimation factor 12.

At 150 MS/s, the 50 MHz mixer translates the desired chirp's positive-frequency
band from 47.5–52.5 MHz to −2.5–+2.5 MHz, centered at 0 MHz. Its negative-frequency band
translates to −102.5–−97.5 MHz, equivalent to +47.5–+52.5 MHz at the sampled
150 MS/s rate. The undesired 70 MHz probe translates to +20 MHz; its negative
component translates to −120 MHz, equivalent to +30 MHz. The first FIR
attenuates the +30 MHz component before `/3`. The +20 MHz interferer remains
within the first stage's transition/passband region and must be attenuated by
the second FIR before `/4`; otherwise it aliases to −5 MHz at the 12.5 MS/s
output rate. This probe demonstrates rejection at one interference frequency,
not across the full undesired band. The public response API and its acceptance
metric provide the broader filter-response evidence. Finite-record FFT plots
show spectral locations and levels, with leakage from record boundaries; they
are not filter-response or alias-rejection acceptance measurements.

Displayed configuration and timing tables report rates, FIR taps, sample
counts, duration, delay, and startup span without hiding them in console
messages. Expected dimensions: `[88236,1]` real ADC samples become `[7353,1]`
complex output samples. The script checks output shape, complex type, and
repeat-call equality. Its output spectrum shows energy across the translated
chirp band rather than a single-frequency peak. Inspect the input one-sided
spectrum, output two-sided spectrum, and startup I/Q plot. Both spectra use dB
re 1 ADC count; I/Q remains a linear signed
sample plot. The output spectrum omits the first 62 output samples from
analysis; the DDC output itself retains every produced row, including startup
rows. Displayed response metric tables and figures describe the filter design,
separately from the finite-record chirp/interference spectra.

The script estimates output instantaneous frequency from phase differences
between adjacent complex samples. It compares mean early- and late-PRI
estimates with the expected chirp frequencies at the corresponding delay-aware
sample positions; averaging reduces noise-driven sample-to-sample phase
jitter. Both errors must be within 2 kHz. This checks sweep direction,
frequency span, and timing at those two windows. It is separate from the
broadband alias-rejection response metric.

All four figure windows request `Position` `[1 1 1100 750]` before docking.
MATLAB's dock container can adjust a docked figure's actual position and size;
the requested rectangle does not guarantee the final pane geometry.

## Processing chain and units

| Stage | Operation and coefficients | Rate and signal |
| --- | --- | --- |
| Input | One complete physical PRI; finite real `double` `[N,C]`, in ADC-count units here | 150 MS/s, `[88236,1]` in this example |
| Mixer | Multiply by the complex 50 MHz oscillator, using local index `n = 0` | Complex, 150 MS/s |
| FIR 1 | 25 taps (order 24), 25 MHz low-pass cutoff | Complex, 150 MS/s |
| Decimate 1 | Keep every third filtered sample | Complex, 50 MS/s |
| FIR 2 | 241 taps (order 240), 5.625 MHz low-pass cutoff | Complex, 50 MS/s |
| Decimate 2 | Keep every fourth filtered sample | Complex, 12.5 MS/s |
| Gain compensation | Multiply final decimated samples by two | Complex `[N/12,C]`; 7,353 rows here |

`N` counts successive ADC samples in rows; `C` counts independent channels in
columns. For an input row count divisible by 12, the returned shape is
`[N/12,C]`. The two decimation factors `/3` and `/4` produce the combined `/12`
rate change. The first FIR protects the `/3` operation; the second FIR selects
the approximately ±5 MHz desired baseband and protects `/4` aliasing.

For a real cosine or narrowband chirp with peak amplitude `A`, complex mixing
leaves the desired complex envelope at `A/2`. The approved fixed factor-two
gain restores peak envelope amplitude toward `A`, subject to FIR gain, phase
response, and residual image. It preserves input units, doubles noise
amplitude, and does not improve SNR. It does not calibrate ADC counts to volts.
FIR coefficients, response metrics, state, timing, output shape, and API remain
unchanged by this gain.

## State, startup, and timing

Every PRI begins with a fresh mixer phase index, FIR delay state, and `/3` and
`/4` decimation phases. State advances only within that call and is discarded
at the PRI boundary, so repeat or reordered calls produce the same per-PRI
result. At 150 MHz, a 50 MHz oscillator repeats every three ADC ticks; PRI
starts aligned to 12 ADC ticks therefore preserve global phase mathematically
when the local index resets to zero. Floating-point evaluation at large global
indices need not be bit-identical to local-index evaluation.

The cascade group delay is 372 ADC sample periods, or 31 output sample periods
(2.48 microseconds). Its full memory span is 744 ADC sample periods, or 62
output periods (4.96 microseconds). Delay describes nominal waveform
displacement; memory describes how much prior input may influence an output.
They answer different questions. The caller applies the 372-tick coordinate
compensation exactly once. The scalar-double `metadata` fields are
`inputSampleCount`, `outputSampleCount`, `decimationFactor`,
`groupDelayInputSamples`, `groupDelayOutputSamples`, `startupInputSamples`,
and `startupOutputSamples`. They describe sample-domain behavior only; they
contain no global timestamps or range coordinates.

The DDC returns produced rows only: it appends no zero input and emits no
flushed tail. Downstream range processing owns complete-window validity for
startup, blanking, and PRI-end truncation. Padding cannot recreate missing or
blanked physical samples. The walkthrough's startup plot marks the boundary
between the 62 startup samples and subsequent samples; its FFT excludes those
rows only to make the post-startup signal easier to inspect.

## Full-scan integration check

![Per-PRI scan loop: skip transition gaps or make one fresh-state DDC call for each physical PRI](assets/ddc-algorithm-state.svg)

The scan view shows the caller retaining global timing, skipping transition
gaps, and making one fresh-state call for each physical PRI. From the
repository root, run:

```matlab
addpath("src")
addpath("tests/ddc")
runDdcScanCheck(fullfile(tempdir, "ddc-pri-scan"))
```

The optional output directory receives response figures; MATLAB and `gramm`
are required for export. This separate integration check covers 147 physical
PRIs and four transition gaps. Its scan metrics and figures are not outputs
from the one-PRI teaching script.

The one-PRI script also plots the public response API's principal stage and
cascade responses, plus the non-principal cascade alias envelope. The latter
does not draw the direct principal stopband term, though the full acceptance
metric includes that term. These plots describe designed-filter response, not
the finite-record input/output FFTs.
The scan check can export [stage 1 alias response](assets/ddc-stage1-alias-response.png),
[stage 2 alias response](assets/ddc-stage2-alias-response.png),
[cascade alias response](assets/ddc-cascade-alias-response.png), and
[passband zoom](assets/ddc-passband-zoom.png). The frozen response profile is
`cascade-peak-v1`: it measures principal cascade passband ripple and includes
both the non-principal alias envelope and direct principal stopband term in
full-cascade alias rejection. The cascade-envelope figure displays only the
non-principal envelope, not that direct principal term. Acceptance requires
the exact −25 to +25 MHz input grid at 1 kHz spacing, including endpoints;
custom grids are diagnostic.

## Evidence and limits

The script's figures and assertions illustrate one synthetic PRI. They do not
measure complete receiver detection, range-window validity, hardware behavior,
or real-time performance. Existing scan, suite, fixture, and analytic results
are separate evidence with scopes recorded in [ADR 0022](../adr/0022-adopt-independent-pri-ddc-processing.md)
and the [implementation plan](../plans/ddc-pri-processing.md). In particular,
historical `independent-pri-v1` comparisons remain v1 evidence; the current
`independent-pri-v2` profile includes factor-two compensation. The pinned
DDC-002 replay remains historical continuous-state evidence, not per-PRI
acceptance evidence. None of these checks establishes a full-CPI, global-tick,
or hardware error bound, or full verification of
[RAD-V1-002](../requirements/radar-matlab-v1.md#requirements) or
[RAD-V1-023](../requirements/radar-matlab-v1.md#requirements).
