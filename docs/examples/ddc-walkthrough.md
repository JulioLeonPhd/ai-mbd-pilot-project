# DDC walkthrough

These diagrams explain the per-PRI DDC contract. The algorithm view shows the
sample path and rate changes; the state view shows the local sample loop and
where its state is discarded. Each channel uses the same oscillator definition
and FIR coefficients, with its own FIR delay state. No state carries between
physical PRI calls.

![DDC sample flow: complex mixing, two FIR and decimation stages, and the resulting rates](assets/ddc-algorithm.svg)

![Per-PRI scan loop: caller selects priming and usable PRIs, skips gaps, and discards fresh local DDC state after each call](assets/ddc-algorithm-state.svg)

The algorithm view maps to [signal and state](#follow-the-signal-and-state)
and [stimulus](#run-the-example). The approved call processes one physical PRI
as a vectorized `[N,C]` array. The state view maps caller scan records to DDC
calls, shows transition gaps outside those calls, and marks where each call's
local state is discarded.

This MATLAB example follows a synthetic one-channel ADC scan through the
floating-point digital down-converter (DDC). The live API processes one complete
physical PRI per call:
`[output, metadata] = radardemo.ddc.processFrame(adcPriSamples, design)`.
Every call starts with fresh local state and a local sample index of zero; the
caller selects and converts each PRI and owns its global identity and timing.
The approved API and responsibilities are recorded in
[ADR 0022](../adr/0022-adopt-independent-pri-ddc-processing.md). The scan
stimulus and output observations below document the current per-PRI example.
Historical continuous-state evidence remains separately pinned and is not
acceptance evidence for this profile. The example does not verify the complete
radar receiver or establish hardware performance. A future Simulink model will
use fixed dimensions per configured model.

## Run the example

Prerequisites are MATLAB and Signal Processing Toolbox, which provides `fir1`
and `kaiser` for the filter coefficients. From the repository root, add the
`examples` folder and call the function:

```matlab
addpath("examples")
results = runDdcWalkthrough();
```

The function runs without creating figures or files and returns a metrics
structure. To save response plots, pass an output directory; it is created
when needed:

```matlab
results = runDdcWalkthrough(fullfile(tempdir, "ddc-walkthrough"));
```

The walkthrough creates a complete contiguous ADC `int16` scan buffer of
shape `[10,553,388,1]` (about 21.1 MB) and reads the 151-record schedule. It
retains the four transition intervals in the global timeline but calls the DDC
only for 147 physical PRIs: five priming and 142 usable records. Each selected
slice is converted to finite real double `[N,1]` at the call boundary. In this
run those calls cover 10,125,900 input samples and return 843,825 complex output
samples. The historical 6000-sample continuous-state walkthrough remains in
pinned evidence; it is not a complete physical PRI.

## Follow the signal and state

The input shape is `[N,C]`: rows are successive ADC ticks and columns are
channels. The scan buffer is one channel of quantized `int16` counts; each DDC
call converts one scheduled slice to finite real double `[N,1]`. Values are
synthetic counts, not calibrated volts. This seeded scan uses a 51 MHz tone at
18,000 counts amplitude, a 70 MHz probe at 3,500 counts, and Gaussian noise
with 600-count standard deviation (seed 2219). The 70 MHz probe is illustrative
and outside the final ±5 MHz baseband. Mixing
produces complex samples at 150 MS/s. Stage 1 is a 24th-order, 25-tap FIR with
a 25 MHz cutoff, designed as a two-sided low-pass filter around zero. It runs
at 150 MS/s, then keeps every third output, yielding 50 MS/s. Stage 2 is a
240th-order, 241-tap FIR with a 5.625 MHz cutoff; it selects the desired
approximately ±5 MHz baseband before keeping every fourth output, yielding
12.5 MS/s. The decimation factors are `/3` and `/4`; the combined rate change
is `/12`. Rates are samples per second, while dimensions are sample counts.
For `N` divisible by 12, `[N,C]` input produces `[N/12,C]` output.

Within a PRI, the local oscillator index starts at `n = 0`; FIR delay buffers
and `/3` and `/4` decimation phases are also fresh. Their state advances only
while processing that PRI and is discarded at its end. A later call is
independent of call order. The output retains every produced sample, including
startup, and does not append zeros or emit a causal tail. The caller converts
stored `int16` data to double per PRI, preserves transition gaps in global time,
and applies group-delay compensation exactly once when assigning coordinates.
Returned metadata contains scalar double fields `inputSampleCount`,
`outputSampleCount`, `decimationFactor`, `groupDelayInputSamples`,
`groupDelayOutputSamples`, `startupInputSamples`, and `startupOutputSamples`.
Downstream range processing owns complete-window validity, including startup,
blanking, and PRI-end truncation.

Each output period spans 12 ADC periods. Cascade group delay is 372 ADC sample
periods or 31 output sample periods (2.48 microseconds); the full memory span is
744 ADC sample periods or 62 output periods (4.96 microseconds). Group delay
describes nominal waveform displacement. Full memory describes the prior
filter history that can affect an output. These are distinct quantities. At
150 MHz, the frozen 50 MHz mixer and PRI starts aligned to 12 ADC ticks make
local `n=0` mixing mathematically consistent with global phase. This does not
claim bit-identical floating-point exponent evaluation for large and local
indices. Each real cosine also has a negative-frequency component, which the mixer
translates; these tones do not represent a complete receiver response test.

## Figures and interpretation

Passing an output directory creates four response figures:

- [Stage 1 alias response](assets/ddc-stage1-alias-response.png) shows `/3`
  folding branches over its output Nyquist band.
- [Stage 2 alias response](assets/ddc-stage2-alias-response.png) shows `/4`
  folding branches over its output band.
- [Cascade alias response](assets/ddc-cascade-alias-response.png) shows the
  worst non-principal branch envelope across the complete cascade, referenced
to peak passband gain.
- [Passband zoom](assets/ddc-passband-zoom.png) resolves the final passband.

The saved figure fields are `stage1AliasResponse`, `stage2AliasResponse`,
`cascadeAliasResponse`, and `passbandZoom` in `results.figures`. The approved
response metric profile is `cascade-peak-v1`. Cascade passband
ripple is measured from the principal `|H1*H2|` response. Cascade alias
rejection is referenced to the peak principal passband; stage-2 alias rejection
remains separately referenced to its passband peak. The full-scan run measured
`0.00146437058836 dB` cascade ripple, `87.7676669047 dB` stage-2 alias
rejection, and `85.2548307898 dB` cascade alias rejection. The 32-test per-PRI
oracle suite reported maximum input-peak-normalized error `1.12962634928e-15`
against the independent combined FIR oracle. The separate per-PRI/continuous-
reference comparison after full memory was `3.34852e-11`,
below the independently reviewed `5e-11` bound for this bounded five-PRI
comparison. This is not a full-CPI, global-tick, or hardware error bound. The
frozen DDC-002 full-CPI fixture remains separate historical continuous-state
evidence; its pinned replay passed strict 1/1. The passband zoom uses
scientific dB notation to show ripple much smaller than the `0.1 dB` limit.
`results.recordObservations` includes each record role, PRF index, global start
tick, input/output counts, delay-adjusted first/last output ticks, and peak
output magnitude. These metrics show coordinate mapping and signal scale; they
do not establish range-window validity.

These diagnostic DDC observations do not establish detection performance,
hardware or real-time behavior, complete FIR precursor/waveform retention, or verification
of all applicable requirements. The DDC is one part of the processing path in
[RAD-V1-002](../requirements/radar-matlab-v1.md#requirements); the sampling and
nominal rate chain are described by
[RAD-V1-023](../requirements/radar-matlab-v1.md#requirements). This walkthrough
provides focused evidence about selected DDC behavior, not full verification
of either requirement.
