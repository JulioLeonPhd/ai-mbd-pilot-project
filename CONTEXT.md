# Radar Demonstrator Context

This glossary establishes the project vocabulary for the public AI-assisted
model-based design reference project. The radar is a demonstrator used to
exercise the workflow; it is not the project's primary mission system.

## Project terms

**Model-based design (MBD)**:
A model-based engineering workflow used by this project.

**Radar demonstrator**:
A representative radar processing system used to demonstrate the MBD workflow.

**Device under test (DUT)**:
The radar processing portion evaluated from digitized channel samples through
detection-list generation.

**Detection list**:
The structured set of detected target outputs produced by the DUT.

**Test vector**:
A saved MAT-file containing generated stimulus and associated data for a test,
including the exact radar-configuration and target-scenario versions used.

**Target scenario**:
The input JSON-defined target list used to generate a test vector, including
each target's radar cross section, Cartesian position, and velocity. For the
MVP, target velocity and RCS remain constant over a scan.
