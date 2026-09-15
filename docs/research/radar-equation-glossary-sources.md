# Radar equation glossary research note

## Scope and conventions

This note checks the candidate glossary equations for the project's stationary,
monostatic, pulsed-LFM radar. It is a source note, not an implementation
contract. The project defines positive radial velocity, $v_r>0$, as
**receding**.

Unless stated otherwise, use the analytic-signal convention

$$
x(t)=A(t)e^{j\phi(t)}, \qquad
X(f)=\int_{-\infty}^{\infty}x(t)e^{-j2\pi ft}\,dt,
$$

so instantaneous frequency is $f_i(t)=(2\pi)^{-1}d\phi/dt$. Replacing
$e^{+j2\pi ft}$ by $e^{-j2\pi ft}$, or changing the Fourier-transform
sign, reverses frequency and Doppler signs. MathWorks likewise defines LFM by
its complex envelope and obtains instantaneous frequency by differentiating
phase, although individual MathWorks radar displays use an approaching-positive
speed convention rather than this project's receding-positive convention
([MathWorks, “Linear Frequency Modulated Pulse Waveforms”](https://www.mathworks.com/help/phased/ug/linear-frequency-modulated-pulse-waveforms.html),
[MathWorks, `phased.RangeDopplerResponse`](https://www.mathworks.com/help/phased/ref/phased.rangedopplerresponse-system-object.html)).

## Equation review

### Chirp (linear-frequency-modulated pulse)

**Classification: corrected.** The supplied expression is ambiguous and
dimensionally malformed: its parentheses do not identify the phase terms,
`fmin**t` is not a mathematical operation, and it appears to multiply rather
than add the start-frequency and chirp-rate contributions.

An unambiguous up-chirp complex envelope is

$$
x(t)=A(t)\exp\!\left\{j\left[2\pi f_{\min}t+
\pi\mu t^2+\phi_0\right]\right\},\qquad 0\le t<T,
$$

with $x(t)=0$ outside the pulse when $A(t)$ is a rectangular pulse,
$\mu=(f_{\max}-f_{\min})/T=B/T$ in Hz/s, $B=f_{\max}-f_{\min}>0$,
$T$ the pulse duration, and $\phi_0$ the initial phase. Its instantaneous
frequency is $f_i(t)=f_{\min}+\mu t$. A symmetric baseband sweep uses
$f_{\min}=-B/2$ and $f_{\max}=+B/2$. A down-chirp is represented by a
negative signed sweep $\mu$. MathWorks gives the equivalent centered LFM
complex envelope $A(t)e^{j\pi(B/T)t^2}$ and explicitly distinguishes
positive and symmetric sweep intervals
([MathWorks, “Linear Frequency Modulated Pulse Waveforms”](https://www.mathworks.com/help/phased/ug/linear-frequency-modulated-pulse-waveforms.html),
[MathWorks, `phased.LinearFMWaveform`](https://www.mathworks.com/help/phased/ref/phased.linearfmwaveform-system-object.html)).

### Matched filter

**Classification: corrected.** For the transform convention above, a filter
matched to $s(t)$, with its output peak placed at $t_m$, has

$$
h(t)=K s^*(t_m-t),\qquad
H(f)=K S^*(f)e^{-j2\pi f t_m}
=K|S(f)|e^{-j[\phi_s(f)+2\pi f t_m]},
$$

where $K$ is an arbitrary gain, $^*$ denotes complex conjugation,
$S(f)=|S(f)|e^{j\phi_s(f)}$, and $t_m$ is the chosen peak time/causal
delay. The supplied equation uses $S(f)$, not $S^*(f)$, so its signal-phase
sign is wrong under this convention. MathWorks defines the matched filter as a
time-reversed, conjugated version of the signal and shifts it to make it causal
([MathWorks, “Matched Filtering”](https://www.mathworks.com/help/phased/ug/matched-filtering.html)).

### Uncompressed range resolution

**Classification: conditionally correct.** For an unmodulated rectangular
pulse of duration $T$, the customary nominal two-way range-resolution scale
is

$$
\Delta R_{\text{uncompressed}}\approx \frac{cT}{2},
$$

where $c$ is propagation speed (the vacuum speed of light for the present
radar). This is the spatial length corresponding to the pulse duration; exact
two-target separability depends on pulse shape, processing, sampling, SNR, and
the resolution criterion. MathWorks documents the duration/resolution tradeoff
for rectangular pulses and pulse compression's decoupling of transmitted and
processed duration
([MathWorks, “Linear Frequency Modulated Pulse Waveforms”](https://www.mathworks.com/help/phased/ug/linear-frequency-modulated-pulse-waveforms.html)).

### Range resolution after pulse compression

**Classification: conditionally correct.** The nominal range-resolution scale
for a waveform with effective swept bandwidth $B$ is

$$
\Delta R_{\text{compressed}}\approx \frac{c}{2B}.
$$

Here $B$ is the effective signal bandwidth in hertz. Windowing, mismatch,
finite sampling, and the selected mainlobe/separability definition change the
actual response. MathWorks uses $B=c/(2\Delta R)$ when deriving pulse
bandwidth from desired range resolution
([MathWorks, “Measure Intensity Levels Using the Intensity Scope”](https://www.mathworks.com/help/phased/ug/measure-intensity-levels-using-the-intensity-scope.html)).

### Doppler and radial-velocity resolution

**Classification: corrected.** For $N_p$ uniformly spaced coherent pulses at
PRF, the coherent processing interval is approximately
$T_{\mathrm{CPI}}=N_p/\mathrm{PRF}$, giving native DFT spacing

$$
\Delta f_d=\frac{\mathrm{PRF}}{N_p}=\frac{1}{T_{\mathrm{CPI}}},
\qquad
\Delta v=\frac{\lambda}{2}\Delta f_d
=\frac{\lambda\,\mathrm{PRF}}{2N_p}.
$$

Here $\lambda=c/f_c$, $f_c$ is carrier frequency, and $N_p$ is the
number of coherent slow-time samples. This is a nominal Rayleigh/DFT resolution
scale; windowing changes mainlobe width.

If the $N_p$ samples are zero-padded to $N_{\mathrm{FFT}}=z_pN_p$, the
displayed grid spacing becomes

$$
\delta v_{\text{grid}}=
\frac{\lambda\,\mathrm{PRF}}{2N_{\mathrm{FFT}}}
=\frac{\lambda\,\mathrm{PRF}}{2z_pN_p},
$$

but physical resolution does not improve. Thus `Np^zp` is wrong whether `^`
means exponentiation or was intended as multiplication. MathWorks states both
$\Delta f_d=\mathrm{PRF}/N$ and that zero-padding interpolates the spectrum
without improving resolution
([MathWorks, “Doppler Shift and Pulse-Doppler Processing”](https://www.mathworks.com/help/phased/ug/doppler-shift-and-pulse-doppler-processing.html),
[MathWorks, “Doppler Estimation”](https://www.mathworks.com/help/phased/ug/doppler-estimation.html)).

### Point-target radar range equation

**Classification: conditionally correct after restoring multiplication.** For
a deterministic point target in the standard free-space bistatic form,

$$
P_r=\frac{P_tG_tG_r\lambda^2\sigma}
{(4\pi)^3R_t^2R_r^2L}.
$$

For a monostatic radar, $R_t=R_r=R$, so

$$
P_r=\frac{P_tG_tG_r\lambda^2\sigma}
{(4\pi)^3R^4L}.
$$

The user's `RCSlambda^2` must mean $\sigma\lambda^2$. Here $P_t$ is
transmit power, $P_r$ received power at the receiver input, $G_t,G_r$ are
dimensionless antenna power gains in the target direction, $\sigma$ is RCS
in square metres, $R_t,R_r$ are transmit/receive ranges, and $L\ge1$ is a
dimensionless aggregate loss factor. The formula excludes unmodeled propagation,
multipath, fluctuation, polarization, and processing effects unless represented
in the chosen factors
([MathWorks, “Radar Equation”](https://www.mathworks.com/help/radar/ug/radar-equation.html)).

### Thermal noise

**Classification: corrected.** Do not call $kTBF$ $N_0$. For the usual
one-sided available-noise convention,

$$
N_0=kT \quad [\mathrm{W/Hz}],\qquad
N=kTB \quad [\mathrm{W}],
$$

where $k$ is Boltzmann's constant, $T$ is absolute noise temperature, and
$B$ is equivalent noise bandwidth. With system equivalent input noise
temperature $T_{\mathrm{sys}}$, use $N=kT_{\mathrm{sys}}B$. If instead a
receiver noise factor $F$ is referenced to $T_0$ and the input source is at
that same reference temperature, the corresponding total input-referred result
is $N=kT_0BF$; receiver equivalent noise temperature is
$T_e=(F-1)T_0$. Do not multiply an already complete
$T_{\mathrm{sys}}$ by $F$, because that can double-count receiver noise.
MathWorks states $N=kTB$, distinguishes noise temperature from noise figure,
and notes that noise figure excludes antenna noise
([MathWorks, “Model Noise in an RF System”](https://www.mathworks.com/help/simrf/ug/modeling-noise-in-an-rf-system.html),
[MathWorks, `comm.ThermalNoise`](https://www.mathworks.com/help/comm/ref/comm.thermalnoise-system-object.html)).

### Maximum unambiguous radial velocity

**Classification: conditionally correct.** Uniform slow-time sampling at PRF
has an unaliased Doppler interval $-\mathrm{PRF}/2\le f_d<\mathrm{PRF}/2$.
For monostatic Doppler magnitude $|f_d|=2|v_r|/\lambda$,

$$
|v_r|<\frac{\lambda\,\mathrm{PRF}}{4},
$$

with $\lambda\mathrm{PRF}/4$ commonly quoted as the maximum unambiguous
speed magnitude. Endpoint ownership depends on the chosen half-open FFT grid.
Staggered/multiple PRFs can support ambiguity unfolding beyond this native
single-PRF interval. MathWorks identifies $\mathrm{PRF}/2$ as the maximum
unambiguous Doppler shift and divides the one-way speed conversion by two for
monostatic propagation
([MathWorks, “Doppler Estimation”](https://www.mathworks.com/help/phased/ug/doppler-estimation.html)).

### Doppler frequency

**Classification: corrected.** Under this project's positive-receding velocity
and the $e^{+j2\pi ft}$ analytic-signal convention above, a stationary
monostatic radar gives

$$
f_d=-\frac{2v_r}{\lambda}=-\frac{2v_rf_c}{c}.
$$

Thus a receding target has negative Doppler and an approaching target has
positive Doppler. If only magnitude is meant,
$|f_d|=2|v_r|f_c/c$. The user's first form should use radial velocity
$v_r$, not a velocity resolution $\Delta v$; its static-radar form has the
right magnitude but needs the sign convention. MathWorks documents the
approaching-positive one-way relation $\Delta f=+v/\lambda$; the monostatic
factor of two comes from the outbound and return paths
([MathWorks, “Doppler Shift and Pulse-Doppler Processing”](https://www.mathworks.com/help/phased/ug/doppler-shift-and-pulse-doppler-processing.html),
[MathWorks, “Doppler Estimation”](https://www.mathworks.com/help/phased/ug/doppler-estimation.html)).

### Beam dwell time (informally, “cell time”)

**Classification: corrected terminology and scope.** Use **beam dwell time** or
**time on target** for the interval during which a target is illuminated by the
main beam. “Cell time” is ambiguous because range, Doppler, and angle cells are
processing bins rather than a single shared time interval. For a continuously
scanning beam with 3 dB (half-power) beamwidth $\theta_{3\mathrm{dB}}$ and
angular scan rate $\omega_s$, in consistent angular units,

$$
T_{\mathrm{dwell}}=\frac{\theta_{3\mathrm{dB}}}{\omega_s}.
$$

MathWorks defines dwell time as the target-illumination interval and gives this
beamwidth-over-scan-rate relationship. It also defines the number of transmitted
pulses available in a dwell as

$$
N_p=\left\lfloor T_{\mathrm{dwell}}\,\mathrm{PRF}\right\rfloor.
$$

If those pulses form one coherent processing interval, then
$T_{\mathrm{CPI}}\approx N_p/\mathrm{PRF}\le T_{\mathrm{dwell}}$, so the
nominal Doppler resolution is $\Delta f_d=1/T_{\mathrm{CPI}}$ and
$\Delta v=\lambda/(2T_{\mathrm{CPI}})$. The number of output Doppler bins is
still a processing choice and need not equal $N_p$
([MathWorks, “Swerling 1 Target Models,” Dwell Time and Radar Scan](https://www.mathworks.com/help/phased/ug/swerling-1-target-models.html),
[MathWorks, “Radar Data Cube,” Slow Time Samples](https://www.mathworks.com/help/phased/gs/radar-data-cube.html)).

Dwell time constrains how many pulses can be integrated at one look direction,
but it does not by itself determine the number of azimuth looks. For a sector
width $\Theta_{\mathrm{sector}}$ and chosen angular look spacing
$\Delta\theta_{\mathrm{look}}$, a nominal one-dimensional count is

$$
N_{\mathrm{az}}\approx
\left\lceil\frac{\Theta_{\mathrm{sector}}}
{\Delta\theta_{\mathrm{look}}}\right\rceil,
$$

with the look spacing selected from beamwidth, overlap, and coverage criteria.
MathWorks' electronic-scanning example likewise derives the scan grid from the
3 dB beamwidth and a chosen overlapping scan step
([MathWorks, “Electronic Scanning Using a Uniform Rectangular Array”](https://www.mathworks.com/help/phased/ug/scan-radar-using-a-uniform-rectangular-array.html)).

Dwell time also does **not** determine the number of range cells. Range is the
fast-time dimension: its extent comes from the receive window, while its sample
or processed-bin spacing comes from fast-time sampling and range processing.
For processed range span $R_{\max}-R_{\min}$ and chosen range-grid spacing
$\delta R$, a nominal count is

$$
N_R\approx
\left\lceil\frac{R_{\max}-R_{\min}}{\delta R}\right\rceil.
$$

This grid spacing is distinct from physical range resolution
$c/(2B)$; zero-padding or resampling can change the number of grid points
without changing resolution. MathWorks identifies fast-time intervals as range
bins and documents the output range-grid length as a function of input
fast-time samples and the selected range-processing configuration
([MathWorks, “Radar Data Cube,” Fast Time Samples](https://www.mathworks.com/help/phased/gs/radar-data-cube.html),
[MathWorks, `phased.RangeResponse`](https://www.mathworks.com/help/phased/ref/phased.rangeresponse-system-object.html)).

### Uniform-linear-array factor and 3 dB beamwidth

**Classification: array-factor form is conditionally correct; terminology and
approximations need correction.** For $N$ identical isotropic point elements
with uniform complex weights, spacing $d$, wavenumber $k=2\pi/\lambda$, and a
steering direction $\theta_0$, define

$$
\Delta u=\sin\theta-\sin\theta_0,\qquad \psi=kd\,\Delta u.
$$

Under the stated phase convention, the normalized complex field or voltage
array factor is

$$
AF_N(\theta)=\frac{1}{N}\sum_{n=0}^{N-1}e^{jn\psi}
=e^{j(N-1)\psi/2}\frac{\sin(N\psi/2)}{N\sin(\psi/2)}.
$$

Changing the transmit/receive or phasor convention can conjugate this
expression without changing its magnitude. The supplied sum therefore has the
right normalized ULA form, subject to a declared convention and a closing
parenthesis, but it is not “total energy contribution.” It is an array factor:
the normalized array-factor power pattern is $|AF_N(\theta)|^2$. The total
field pattern also includes the element pattern, and absolute radiated or
received power requires the relevant amplitude, impedance, gain, and
normalization factors. MathWorks likewise defines array factor as the weighted
steering-vector response, distinguishes field from its squared-magnitude power
pattern, and treats element pattern and array factor as separate factors
([MathWorks, “Element and Array Radiation and Response Patterns”](https://www.mathworks.com/help/phased/ug/element-and-array-radiation-patterns-and-responses.html),
[MathWorks, `arrayfactor`](https://www.mathworks.com/help/phased/ref/arrayfactor.html)).

For a long, uniformly illuminated continuous line aperture of effective length
$L$, or as the large-$N$ approximation to the uniformly weighted ULA near its
main lobe, state the sinc convention explicitly:

$$
AF(\theta)\approx e^{j\phi(\theta)}
\operatorname{sinc}\!\left(\frac{L}{\lambda}\Delta u\right),
\qquad
\operatorname{sinc}(x)=\frac{\sin(\pi x)}{\pi x}.
$$

The phase $e^{j\phi(\theta)}$ depends on the aperture origin and disappears
from the power pattern. If instead $\operatorname{sinc}(x)=\sin x/x$ is used,
its argument must be $\pi L\Delta u/\lambda$. For the discrete point-element
ULA above, matching the main-lobe nulls gives the effective uniform-aperture
length $L=Nd$; the literal distance between the first and last element centers
is only $D=(N-1)d$. Neither is necessarily the physical panel width.

The half-power points of the uniform-aperture approximation satisfy
$|\operatorname{sinc}(L\Delta u/\lambda)|^2=1/2$, giving
$|\Delta u|\approx0.443\lambda/L$. Hence the angular 3 dB beamwidth is

$$
\theta_{3\mathrm{dB}}
\approx
\sin^{-1}\!\left(\sin\theta_0+0.443\frac{\lambda}{L}\right)
-
\sin^{-1}\!\left(\sin\theta_0-0.443\frac{\lambda}{L}\right).
$$

For a narrow main lobe away from endfire, this reduces to

$$
\theta_{3\mathrm{dB}}
\approx\frac{0.886\lambda}{L\cos\theta_0}\quad\text{radians},
$$

and only at broadside, $\theta_0=0$, to the supplied
$0.886\lambda/L$ radians. NASA's half-power-beamwidth note gives the same
$0.443\lambda/L$ sine-space half-width, while MathWorks defines beamwidth as
the angular separation of the two 3 dB-down power-pattern points
([NASA Tech Brief, “Half-Power Beamwidth (3 db beamwidth)”](https://ntrs.nasa.gov/citations/19710002919),
[MathWorks, `beamwidth`](https://www.mathworks.com/help/phased/ref/phased.ula.beamwidth.html)).
Tapering, finite element patterns, mutual coupling, finite-$N$ effects, and
wide-angle scanning change the result.

For the project's exact baseline, $f_c=2.99792458$ GHz and $\lambda=0.1$ m by
design, with $d=0.05$ m and horizontal center span $15d=0.75$ m. For 128
pulses, $\Delta v=\mathrm{PRF}/2560$; see [ADR 0015](../adr/0015-adopt-exact-10cm-free-space-wavelength.md).
The effective aperture convention remains $L=Nd=8\lambda$
in this main-lobe approximation, whereas the accepted center-to-center span is
$D=15d=7.5\lambda$. The broadside approximation then gives about $6.35^\circ$,
consistent with the project's ideal-array numerical study; it must not be
presented as a physical 8-wavelength panel width.

## Project-specific numerical cross-check

For the current $f_c=2.99792458$ GHz, $B=10$ MHz, $T=40$ microsecond candidate,
$\lambda=0.1$ m exactly by design, with nominal uncompressed and compressed
range scales
are approximately 5.996 km and 14.990 m, respectively. For 128 usable pulses
at one PRF, $\Delta v=\mathrm{PRF}/2560$, while the native
single-PRF limit is $v_{\max}=\lambda\,\mathrm{PRF}/4$. These are derived
cross-checks; each dwell's actual PRF determines its numerical velocity values.
The candidate parameters and accepted sign convention come from
[ADR 0012](../adr/0012-adopt-50m-separability-and-narrowband-ddc-candidate.md),
[ADR 0014](../adr/0014-adopt-revised-v1-analytic-simulation-baseline.md),
[ADR 0015](../adr/0015-adopt-exact-10cm-free-space-wavelength.md), and
[ADR 0009](../adr/0009-radar-mvp-acceptance-and-ambiguity-requirements.md).
