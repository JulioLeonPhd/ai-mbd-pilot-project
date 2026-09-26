# Radar Demonstrator Context

This glossary defines the radar and signal-processing terms used by the project.
The radar is a learning demonstrator for model-based design; it is not a mission
system. Workflow and contribution vocabulary lives in
[the human-led workflow](docs/agents/human-led-workflow.md). Historical
mathematical conventions and equations are preserved in
[the radar equations reference](docs/reference/radar-equations.md).

## Radar and DSP terms

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

**Module**:
A logical DSP responsibility with defined interfaces. The MATLAB project
represents modules with namespaces; the corresponding future Simulink component
need not mirror MATLAB functions one-for-one.

**Frame**:
A buffered block of consecutive samples processed together. Under frame
processing, an $N\times C$ matrix has sample times in rows and channels in
columns; whether a block is interpreted as a frame depends on the processing
block's input-processing setting. A frame is not inherently a radar pulse, PRI,
or CPI. See [MathWorks' sample- and frame-based concepts](https://www.mathworks.com/help/dsp/ug/sample-and-frame-based-concepts.html).

**Chunk**:
The current MATLAB DDC implementation's term for one finite $N\times C$ block
passed to `processChunk`. Its size is a processing and memory choice; successive
chunks representing one continuous stream preserve mixer count, FIR history,
and decimation phase. In this project, *frame* is the preferred explanatory
term for blocks buffered for processing; this terminology does not prescribe a
Simulink block's frame setting or fixed sample size.

**Pulse accumulation**:
Collecting successive pulses into a slow-time ensemble for Doppler processing.
This describes the acquisition/buffering operation; it does not specify which
module owns the buffer. See [MathWorks' range-Doppler processing description](https://www.mathworks.com/help/phased/ug/range-doppler-response.html).

**Corner turning**:
Reordering pulse-by-range data so each range cell's slow-time sequence is
available to a Doppler bank. This is a data-access order change, often described
as a transpose; it does not require a physical matrix copy or prescribe a
buffer implementation. See [TI's transpose-write/read technique](https://www.ti.com/lit/an/swra564/swra564.pdf).

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
