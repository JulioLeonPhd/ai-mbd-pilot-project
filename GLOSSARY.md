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
