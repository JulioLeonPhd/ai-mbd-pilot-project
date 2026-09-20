# Radar Demonstrator Context

This glossary establishes the project vocabulary for the public AI-assisted
model-based design reference project. The radar is a demonstrator used to
exercise the workflow; it is not the project's primary mission system.

## Project terms

**Exact RF baseline**:
The project uses exact free-space wavelength $\lambda=0.1$ m with
$f_c=2997924580$ Hz derived from exact $c=299792458$ m/s. Half-wave element
center spacing is $d=\lambda/2=0.05$ m. For the 16×4 array, center-to-center
spans are 0.75 m horizontal and 0.15 m vertical; these are distinct from
element dimensions and physical panel size. See [ADR 0015](docs/adr/0015-adopt-exact-10cm-free-space-wavelength.md).

**Model-based design (MBD)**:
A model-based engineering workflow used by this project.

**Radar demonstrator**:
A representative radar processing system used to demonstrate the MBD workflow.

**Device under test (DUT)**:
The radar processing portion evaluated from digitized channel samples through
detection-list generation.

**Detection list**:
The structured set of detected target outputs produced by the DUT.

**Commanded azimuth look**:
The selected receive azimuth used to form a directional receive look. V1
associates detections with this commanded look rather than claiming sub-beam
azimuth estimation.

**V1 reported azimuth**:
The commanded azimuth look associated with a detection. V1 does not claim
sub-beam azimuth estimation; multi-beam or monopulse refinement is future work.

**Test vector**:
A saved MAT-file containing generated stimulus and associated data for a test,
including the exact radar-configuration and target-scenario versions used.

**Clock epoch**:
The simulation-time origin used to interpret sample timing. It is distinct
from wall-clock artifact provenance.

**Target scenario**:
The input JSON-defined target list used to generate a test vector, including
each target's radar cross section, Cartesian position, and velocity. For the
MVP, target velocity and RCS remain constant over a scan.

**Cell time**:
The project-facing term for beam dwell time, also called time on target: the
interval a target is illuminated by the main beam. For a continuously scanning
beam, a conditional estimate is

$$
T_{\rm cell}\approx\frac{\theta_{3\mathrm{dB}}}{\omega_{\rm scan}},
$$

where $\theta_{3\mathrm{dB}}$ is the half-power beamwidth and
$\omega_{\rm scan}$ is angular scan rate in consistent units. Cell time
influences azimuth sampling/look count and limits available pulses and CPI,
which in turn limits Doppler resolution; it does not determine the number of
range cells, set by receive-window range extent and range-bin spacing. FFT
sizing and other processing choices also determine Doppler-bin count.

**Uniform-linear-array factor**:
For a normalized $N$-element uniform linear array (ULA) of isotropic point
elements with spacing $d$, the complex field/voltage array factor is

$$
AF_N(\theta)=\frac{1}{N}\sum_{n=0}^{N-1}e^{jn\psi}
=e^{j(N-1)\psi/2}\frac{\sin(N\psi/2)}{N\sin(\psi/2)},\qquad
\psi=k d(\sin\theta-\sin\theta_0),\quad k=\frac{2\pi}{\lambda}.
$$

Here $\theta$ is observation angle, $\theta_0$ steering angle, and $\lambda$
wavelength. The normalized power pattern is $|AF_N(\theta)|^2$; this is an
array factor, not energy. A continuous uniform-aperture approximation is

$$
AF(\theta)\approx e^{j\phi(\theta)}\operatorname{sinc}
\!\left(\frac{L\,\Delta u}{\lambda}\right),\qquad
\operatorname{sinc}(x)=\frac{\sin(\pi x)}{\pi x},\qquad
\Delta u=\sin\theta-\sin\theta_0.
$$

For the discrete point-element ULA, use effective $L=Nd$ when matching
main-lobe nulls; the first-to-last element-center span is $D=(N-1)d$.
Neither quantity necessarily equals physical panel width. Element pattern,
tapering, coupling, and finite-array effects alter the complete pattern.

**ULA 3 dB beamwidth**:
For the uniform-aperture approximation, the exact sine-space half-power
condition is $|\operatorname{sinc}(L\Delta u/\lambda)|^2=1/2$. A useful
narrow-beam approximation in radians is

$$
\Delta\theta_{3\mathrm{dB}}\approx
\frac{0.886\,\lambda}{L\cos\theta_0},
$$

which reduces at broadside ($\theta_0=0$) to
$\Delta\theta_{3\mathrm{dB}}\approx0.886\lambda/L$. This approximation is
not exact or universally valid, especially away from broadside or for arrays
with nonuniform element patterns, tapering, coupling, or finite-aperture
effects.

## Radar equations

The formulas below use the analytic-signal and Fourier convention

$$
x(t)=A(t)e^{j\phi(t)},\qquad X(f)=\int_{-\infty}^{\infty}x(t)e^{-j2\pi ft}\,dt.
$$

The project convention is positive radial velocity $v_r>0$ for a receding
target. These are nominal or conditional scales, not exact separability or
detection guarantees; waveform, window, sampling, SNR, and the selected
criterion affect measured performance. See the [radar equation research note](docs/research/radar-equation-glossary-sources.md)
for derivations and sources.

**LFM chirp**:

$$
x(t)=A(t)\exp\!\left\{j\left[2\pi f_1t+\pi\mu t^2+\phi_0\right]\right\},\quad
0\le t<T_p,
$$

where $A(t)$ is the pulse envelope, $T_p$ is pulse duration,
$\mu=(f_2-f_1)/T_p$ is signed sweep rate in hertz per second,
$B=|f_2-f_1|$ is nonnegative swept bandwidth, and $\phi_0$ is initial
phase. The instantaneous frequency is $f_i(t)=f_1+\mu t$; an up-chirp has
$\mu>0$ and a down-chirp has $\mu<0$.

**Matched filter**:

$$
h(t)=K s^*(t_m-t),\qquad H(f)=K S^*(f)e^{-j2\pi f t_m},
$$

where $s(t)$ is the reference signal, $S(f)$ its transform, $K$ an
arbitrary gain, $^*$ complex conjugation, and $t_m$ the chosen output-peak
time (causal delay).

**Uncompressed range resolution**: For an unmodulated rectangular pulse, the
nominal scale is $\Delta R_{\rm uncompressed}\approx cT_p/2$, where $c$ is
propagation speed (the vacuum speed of light here).

**Pulse-compressed range resolution**: For effective bandwidth $B$, the
nominal scale is $\Delta R_{\rm compressed}\approx c/(2B)$.

**Doppler/velocity resolution**: For $N_p$ coherent pulses at pulse
repetition frequency $\mathrm{PRF}$, $T_{\rm CPI}=N_p/\mathrm{PRF}$ and

$$
\Delta f_d=\frac{\mathrm{PRF}}{N_p},\qquad
\Delta v=\frac{\lambda\,\mathrm{PRF}}{2N_p},\qquad \lambda=\frac{c}{f_c},
$$

where $f_c$ is carrier frequency. This is a nominal native DFT/Rayleigh
scale; windowing changes mainlobe width.

**Zero-padded Doppler grid spacing**: If $N_{\rm FFT}=z_pN_p$, displayed
grid spacing is $\delta v_{\rm grid}=\lambda\,\mathrm{PRF}/(2N_{\rm FFT})
=\lambda\,\mathrm{PRF}/(2z_pN_p)$. Zero-padding interpolates the grid; it
does not improve physical Doppler resolution.

**Monostatic radar equation**:

$$
P_r=\frac{P_tG_tG_r\lambda^2\sigma}{(4\pi)^3R^4L},
$$

where $P_t$ and $P_r$ are transmit and received powers, $G_t,G_r$ are
dimensionless power gains, $\sigma$ is radar cross section in m$^2$,
$R$ is target range, and $L\ge1$ is aggregate loss. This is a
free-space point-target model.

**Thermal noise density and power**:

$$
N_0=kT_n\ [\mathrm{W/Hz}],\qquad N=kT_nB\ [\mathrm{W}],
$$

where $k$ is Boltzmann's constant, $T_n$ absolute noise temperature, and
$B$ equivalent noise bandwidth. The $N_0=kT_n$ expression is the usual
one-sided available-noise convention. With system temperature use
$N=kT_{\rm sys}B$. Alternatively, for reference temperature $T_0$ and
noise factor $F$, use $N=kT_0BF$; do not multiply a complete $T_{\rm sys}$
by $F$, which double-counts receiver noise.

**Maximum unambiguous radial velocity**: Uniform slow-time sampling gives
$\lvert f_d\rvert<\mathrm{PRF}/2$, hence the nominal monostatic magnitude
limit $\lvert v_r\rvert<\lambda\,\mathrm{PRF}/4$ (often quoted as
$v_{\max}=\lambda\,\mathrm{PRF}/4$); endpoint ownership depends on the FFT
grid convention.

**Doppler frequency**: Under the convention above, a stationary monostatic
radar has

$$
f_d=-\frac{2v_r}{\lambda}=-\frac{2v_rf_c}{c}.
$$

Thus receding is negative Doppler and approaching is positive; use
$\lvert f_d\rvert=2\lvert v_r\rvert/\lambda$ when only magnitude is meant.
