# Radar equations and conventions

This reference preserves the project equations, mathematical conventions, and
their limits. Domain terms are defined in [CONTEXT.md](../../CONTEXT.md).

## Radar equations

The formulas below use the analytic-signal and Fourier convention

$$
x(t)=A(t)e^{j\phi(t)},\qquad X(f)=\int_{-\infty}^{\infty}x(t)e^{-j2\pi ft}\,dt.
$$

The project convention is positive radial velocity $v_r>0$ for a receding
target. These are nominal or conditional scales, not exact separability or
detection guarantees; waveform, window, sampling, SNR, and the selected
criterion affect measured performance. See the [radar equation research note](../research/radar-equation-glossary-sources.md)
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
