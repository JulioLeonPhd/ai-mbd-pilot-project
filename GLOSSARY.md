# Radar Demonstrator

This glossary defines the radar and signal-processing language used by the
project's learning demonstrator. It covers the modeled radar domain and does
not describe a mission system.

## Language

### Radar processing

**Device under test (DUT)**:
The radar processing system whose input is digitized receive-channel samples
and whose output is a detection list.

**Detection list**:
The collection of target reports produced by radar processing.

**Detection**:
A report that radar processing identifies a candidate target, with measured
or estimated attributes such as range and radial velocity. A detection is an
algorithm output; it is distinct from the target that may have caused it.

**Target**:
An object represented in a target scenario by its radar cross section,
position, and velocity. Target properties describe scenario truth, while a
detection describes a processing result.

**Commanded azimuth look**:
The selected receive direction associated with a radar look. A reported V1
azimuth identifies this commanded look; it does not imply finer angular
estimation within the beam.

**Target scenario**:
A description of the targets present in a simulated radar observation,
including their radar cross sections, positions, and velocities.

### Radar timing and signal dimensions

**Pulse repetition interval (PRI)**:
The physical time between successive transmitted pulses.

**Clock epoch**:
The reference instant from which radar sample and event times are measured.

**Coherent processing interval (CPI)**:
The interval over which successive pulses are coherently processed to estimate
Doppler. For uniformly spaced pulses, its nominal duration is the pulse count
divided by pulse repetition frequency.

**Fast time**:
Time indexing samples within each pulse's receive window. It corresponds to
the range dimension of pulse radar data.

**Slow time**:
Time across successive pulses. It corresponds to the Doppler dimension of
pulse radar data.

**Frame**:
A group of consecutive samples treated together in signal processing. A frame
is not inherently a radar pulse, PRI, or CPI. See [sample- and frame-based
concepts](https://www.mathworks.com/help/dsp/ug/sample-and-frame-based-concepts.html).

**Cell time**:
The time a target is illuminated by the main beam, also called dwell time or
time on target.

**Frequency and sample-rate units**:
MHz describes frequency, such as intermediate frequency or bandwidth; MS/s
describes sample rate.

### Radar and array processing

**Pulse accumulation**:
Collecting successive pulse results into an ensemble for slow-time processing.
See [range-Doppler processing](https://www.mathworks.com/help/phased/ug/range-doppler-response.html).

**Corner turning**:
Reordering pulse-by-range data so that each range cell's slow-time sequence is
available for Doppler processing. It describes data access order, not a
required physical matrix copy.
See TI's [transpose-write/read technique](https://www.ti.com/lit/an/swra564/swra564.pdf).

### Range response

**Effective receive gain**:
The directional receive gain of the evaluated beamformed aperture, including its receive beamforming contribution, rather than the gain of an individual element; this does not imply that multiple elevation streams are combined.

**Range-stage input SNR**:
The ratio of an individual target's mean complex echo power over pulse support to the mean complex noise power at the range-stage input, stated per stream. It describes each target separately, not the power of a coherent sum of target echoes.

**Post-compression SNR**:
The ratio of an isolated target's compressed-response peak power to the mean noise-only output power at the same range bin; it is distinct from input SNR and coherent multi-target peak power.

**Stationary receiver noise**:
Receiver noise is stationary over a stated observation interval when its mean and mean power do not vary with time, and its correlation depends on time separation rather than absolute time. Its samples still fluctuate; stationarity does not mean a constant sequence.

**Radar cross section (RCS)**:
A measure of a target's scattering strength under stated observation conditions, distinct from the received echo amplitude.

**Equal-RCS targets**:
Targets with the same radar cross section under the stated observation conditions; their received echo amplitudes may differ because propagation depends on range.

**Link budget**:
A radar link budget accounts for transmitted power, antenna gains, two-way propagation, target scattering, and system losses to characterize received echo power. Together with receiver noise, it relates that power to SNR at a stated reference plane; any processing gain is identified separately rather than folded into the power accounting.

**Range calibration**:
The correspondence between known echo delays and physical range coordinates. Correct range coordinates are distinct from accurate localization of targets between those coordinates.

**Complex gain**:
The complex amplitude ratio of an output response to a reference response or input echo under stated matching and alignment conditions, with magnitude and phase as distinct aspects. The ratio need not be unity for mismatched or off-grid echoes.

**Phase preservation**:
Retention of an echo's complex phase relative to a defined reference, apart from explicitly modeled phase shifts.

**Nominal range-resolution scale**:
A bandwidth-derived characteristic range scale associated with two-way propagation. It is distinct from the measured width of a compressed response and from demonstrated separability of two targets.

**Compressed-response power FWHM**:
The full width of an isolated compressed-response mainlobe between its half-maximum-power crossings, expressed in time or range; it is distinct from the nominal range-resolution scale and two-target separability.

**Range separability**:
The ability to distinguish range-response peaks from two targets, which does not necessarily imply two downstream detections or reports.

**Complete-window validity**:
Validity of a range response when every sample needed to form it exists and is valid; a zero response alone does not indicate invalidity.
