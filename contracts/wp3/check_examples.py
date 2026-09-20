"""Table-driven conformance checks for the WP3 JSON contract fixtures.

The public checker functions return a report instead of raising for an input
contract error. This keeps producer and consumer diagnostics machine-readable
and lets the manifest exercise deterministic in-memory mutations.
"""

from __future__ import annotations

import copy
import json
import math
import re
from pathlib import Path
from typing import Any, TypeGuard

ROOT = Path(__file__).resolve().parent
EXAMPLES = ROOT / "examples"
MANIFEST_PATH = ROOT / "fixture-manifest.json"
VERSION = re.compile(r"^\d+\.\d+\.\d+(?:-draft\.\d+)?$")
DRAFT_SCHEMA_VERSION = "1.0.0-draft.1"
EXPECTED_DOCUMENT_VERSION = "0.2.0"
SPEED_OF_LIGHT_M_PER_S = 299_792_458
EXPECTED_RF_CARRIER_HZ = 2_997_924_580
EXPECTED_WAVELENGTH_M = 0.1
EXPECTED_ELEMENT_SPACING_RATIO = 0.5
EXPECTED_ELEMENT_SPACING_M = 0.05
FLOAT_TOLERANCE = 1e-15
STAGES = (
    "ddc",
    "azimuth-beamformed",
    "range",
    "doppler",
    "angle",
    "candidate-list",
    "ambiguity-projection",
    "cfar",
    "fusion",
    "cluster",
)
FIXTURE_SCOPES = {"acceptance", "out-of-domain", "unit-only", "provisional"}
ERROR_CODES = {
    "MISSING_FIELD",
    "TYPE_MISMATCH",
    "NONFINITE",
    "DIMENSION_MISMATCH",
    "VERSION_MISMATCH",
    "VALUE_OUT_OF_RANGE",
    "TICK_DISCONTINUITY",
    "INCONSISTENT_RATE",
    "PROVENANCE_MISMATCH",
    "DUPLICATE_ID",
    "METHOD_PENDING",
}


def diagnostic(code: str, path: str, message: str) -> dict[str, str]:
    """Build one contract diagnostic with the stable public fields."""

    if code not in ERROR_CODES:
        raise ValueError(f"unknown WP3 diagnostic code: {code}")
    return {"code": code, "path": path, "message": message}


def _report(artifact: str, diagnostics: list[dict[str, str]]) -> dict[str, Any]:
    return {
        "status": "passed" if not diagnostics else "failed",
        "artifact": artifact,
        "diagnostics": diagnostics,
    }


def _add(diagnostics: list[dict[str, str]], code: str, path: str, message: str) -> None:
    diagnostics.append(diagnostic(code, path, message))


def _field(value: Any, key: str, path: str, diagnostics: list[dict[str, str]]) -> Any:
    if not isinstance(value, dict) or key not in value:
        _add(diagnostics, "MISSING_FIELD", path, "required field is missing")
        return None
    return value[key]


def _text(value: Any, path: str, diagnostics: list[dict[str, str]]) -> bool:
    if not isinstance(value, str) or not value:
        _add(diagnostics, "TYPE_MISMATCH", path, "must be a non-empty string")
        return False
    return True


def _number(
    value: Any,
    path: str,
    diagnostics: list[dict[str, str]],
    *,
    positive: bool = False,
    integer: bool = False,
) -> bool:
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        _add(diagnostics, "TYPE_MISMATCH", path, "must be a number")
        return False
    if not math.isfinite(value):
        _add(diagnostics, "NONFINITE", path, "must be finite")
        return False
    if integer and not isinstance(value, int):
        _add(diagnostics, "TYPE_MISMATCH", path, "must be an integer")
        return False
    if positive and value <= 0:
        _add(diagnostics, "VALUE_OUT_OF_RANGE", path, "must be strictly positive")
        return False
    return True


def _required_number(
    value: dict[str, Any],
    key: str,
    path: str,
    diagnostics: list[dict[str, str]],
    *,
    positive: bool = False,
    integer: bool = False,
) -> bool:
    if key not in value:
        _add(diagnostics, "MISSING_FIELD", path, "required field is missing")
        return False
    return _number(value[key], path, diagnostics, positive=positive, integer=integer)


def _required_text(
    value: dict[str, Any], key: str, path: str, diagnostics: list[dict[str, str]]
) -> bool:
    if key not in value:
        _add(diagnostics, "MISSING_FIELD", path, "required field is missing")
        return False
    return _text(value[key], path, diagnostics)


def _fixture_scope(value: Any, path: str, diagnostics: list[dict[str, str]]) -> bool:
    if not _text(value, path, diagnostics):
        return False
    if value not in FIXTURE_SCOPES:
        _add(
            diagnostics,
            "VALUE_OUT_OF_RANGE",
            path,
            "must be acceptance, out-of-domain, unit-only, or provisional",
        )
        return False
    return True


def _validate_statistic(
    value: Any, path: str, diagnostics: list[dict[str, str]]
) -> None:
    """Validate the shared named scalar statistic record."""

    if not isinstance(value, dict):
        _add(diagnostics, "TYPE_MISMATCH", path, "must be an object")
        return
    fields = {"name", "value", "units", "extensions"}
    _closed(value, fields, path, diagnostics)
    for key in ("name", "value", "units"):
        if key not in value:
            _add(
                diagnostics,
                "MISSING_FIELD",
                f"{path}.{key}",
                "required field is missing",
            )
    _text(value.get("name"), f"{path}.name", diagnostics)
    _number(value.get("value"), f"{path}.value", diagnostics)
    _text(value.get("units"), f"{path}.units", diagnostics)


def _vector(
    value: Any,
    path: str,
    expected_length: int,
    diagnostics: list[dict[str, str]],
) -> None:
    if not isinstance(value, list):
        _add(diagnostics, "TYPE_MISMATCH", path, "must be an array")
        return
    if len(value) != expected_length:
        _add(
            diagnostics,
            "DIMENSION_MISMATCH",
            path,
            f"must have length {expected_length}",
        )
    for index, item in enumerate(value):
        _number(item, f"{path}[{index}]", diagnostics)


def _version(
    value: Any,
    path: str,
    diagnostics: list[dict[str, str]],
    expected: str | None = None,
) -> None:
    if not _text(value, path, diagnostics):
        return
    if VERSION.fullmatch(value) is None:
        _add(diagnostics, "VERSION_MISMATCH", path, "must use semantic versioning")
    elif expected is not None and value != expected:
        _add(
            diagnostics,
            "VERSION_MISMATCH",
            path,
            f"expected {expected}, received {value}",
        )


def _envelope(
    value: Any,
    expected_name: str,
    artifact: str,
    diagnostics: list[dict[str, str]],
    *,
    document_version: str = EXPECTED_DOCUMENT_VERSION,
) -> None:
    if not isinstance(value, dict):
        _add(diagnostics, "TYPE_MISMATCH", artifact, "root must be an object")
        return
    schema_name = _field(value, "schemaName", f"{artifact}.schemaName", diagnostics)
    if schema_name is not None and schema_name != expected_name:
        _add(
            diagnostics,
            "VALUE_OUT_OF_RANGE",
            f"{artifact}.schemaName",
            f"expected {expected_name}",
        )
    _version(
        _field(value, "schemaVersion", f"{artifact}.schemaVersion", diagnostics),
        f"{artifact}.schemaVersion",
        diagnostics,
        DRAFT_SCHEMA_VERSION,
    )
    _version(
        _field(value, "documentVersion", f"{artifact}.documentVersion", diagnostics),
        f"{artifact}.documentVersion",
        diagnostics,
        document_version,
    )
    _text(
        _field(value, "id", f"{artifact}.id", diagnostics),
        f"{artifact}.id",
        diagnostics,
    )
    for key in ("createdUtc", "producer"):
        _text(
            _field(value, key, f"{artifact}.{key}", diagnostics),
            f"{artifact}.{key}",
            diagnostics,
        )


def _closed(
    value: dict[str, Any],
    allowed: set[str],
    path: str,
    diagnostics: list[dict[str, str]],
) -> None:
    """Reject fields outside the versioned artifact's closed schema."""

    for key in value:
        if key not in allowed:
            _add(
                diagnostics,
                "VALUE_OUT_OF_RANGE",
                f"{path}.{key}" if path else key,
                "unknown field is not permitted by the closed schema",
            )


def _validate_configuration(value: Any) -> list[dict[str, str]]:
    diagnostics: list[dict[str, str]] = []
    artifact = "configuration"
    _envelope(value, "radar.configuration", artifact, diagnostics)
    if not isinstance(value, dict):
        return diagnostics
    _closed(
        value,
        {
            "schemaName",
            "schemaVersion",
            "documentVersion",
            "id",
            "createdUtc",
            "producer",
            "rfCarrierHz",
            "ifCenterHz",
            "adcSampleRateHz",
            "adcBits",
            "channelCount",
            "array",
            "waveform",
            "ddc",
            "prfsHz",
            "priSampleCounts",
            "processing",
            "scan",
            "blanking",
            "random",
            "extensions",
        },
        "configuration",
        diagnostics,
    )

    for key in ("rfCarrierHz", "ifCenterHz", "adcSampleRateHz"):
        _required_number(value, key, f"{artifact}.{key}", diagnostics, positive=True)
    if value.get("rfCarrierHz") != EXPECTED_RF_CARRIER_HZ:
        _add(
            diagnostics,
            "VALUE_OUT_OF_RANGE",
            "configuration.rfCarrierHz",
            "must equal the exact 10 cm design carrier",
        )
    if (
        _required_number(
            value, "adcBits", "configuration.adcBits", diagnostics, integer=True
        )
        and value["adcBits"] != 16
    ):
        _add(
            diagnostics, "VALUE_OUT_OF_RANGE", "configuration.adcBits", "must equal 16"
        )
    if (
        _required_number(
            value,
            "channelCount",
            "configuration.channelCount",
            diagnostics,
            integer=True,
        )
        and value["channelCount"] != 64
    ):
        _add(
            diagnostics,
            "DIMENSION_MISMATCH",
            "configuration.channelCount",
            "must equal 16 azimuth elements times 4 elevation elements",
        )

    array = _field(value, "array", "configuration.array", diagnostics)
    if isinstance(array, dict):
        azimuth = array.get("azimuthElements")
        elevation = array.get("elevationElements")
        _required_number(
            array,
            "azimuthElements",
            "configuration.array.azimuthElements",
            diagnostics,
            positive=True,
            integer=True,
        )
        _required_number(
            array,
            "elevationElements",
            "configuration.array.elevationElements",
            diagnostics,
            positive=True,
            integer=True,
        )
        spacing = array.get("elementSpacingWavelengths")
        _required_number(
            array,
            "elementSpacingWavelengths",
            "configuration.array.elementSpacingWavelengths",
            diagnostics,
            positive=True,
        )
        if spacing != EXPECTED_ELEMENT_SPACING_RATIO:
            _add(
                diagnostics,
                "VALUE_OUT_OF_RANGE",
                "configuration.array.elementSpacingWavelengths",
                "must equal a half-wavelength",
            )
        if (
            isinstance(azimuth, int)
            and isinstance(elevation, int)
            and isinstance(value.get("channelCount"), int)
            and azimuth * elevation != value["channelCount"]
        ):
            _add(
                diagnostics,
                "DIMENSION_MISMATCH",
                "configuration.channelCount",
                "array and channel dimensions disagree",
            )
        if isinstance(azimuth, int) and azimuth != 16:
            _add(
                diagnostics,
                "DIMENSION_MISMATCH",
                "configuration.array.azimuthElements",
                "must equal 16",
            )
        if isinstance(elevation, int) and elevation != 4:
            _add(
                diagnostics,
                "DIMENSION_MISMATCH",
                "configuration.array.elevationElements",
                "must equal 4",
            )

    wavelength = SPEED_OF_LIGHT_M_PER_S / EXPECTED_RF_CARRIER_HZ
    if not math.isclose(
        wavelength, EXPECTED_WAVELENGTH_M, rel_tol=0.0, abs_tol=FLOAT_TOLERANCE
    ):
        _add(
            diagnostics,
            "VALUE_OUT_OF_RANGE",
            "configuration.rfCarrierHz",
            "derived wavelength must equal 0.1 m",
        )
    if (
        isinstance(array, dict)
        and array.get("elementSpacingWavelengths") == EXPECTED_ELEMENT_SPACING_RATIO
        and not math.isclose(
            wavelength * EXPECTED_ELEMENT_SPACING_RATIO,
            EXPECTED_ELEMENT_SPACING_M,
            rel_tol=0.0,
            abs_tol=FLOAT_TOLERANCE,
        )
    ):
        _add(
            diagnostics,
            "VALUE_OUT_OF_RANGE",
            "configuration.array.elementSpacingWavelengths",
            "derived spacing must equal 0.05 m",
        )

    waveform = _field(value, "waveform", "configuration.waveform", diagnostics)
    if isinstance(waveform, dict):
        _closed(
            waveform,
            {
                "pulseWidthSec",
                "chirpBandwidthHz",
                "chirpStartHz",
                "chirpStopHz",
                "extensions",
            },
            "configuration.waveform",
            diagnostics,
        )
        for key in ("pulseWidthSec", "chirpBandwidthHz", "chirpStartHz", "chirpStopHz"):
            if key in waveform:
                _number(
                    waveform[key],
                    f"configuration.waveform.{key}",
                    diagnostics,
                    positive=key in {"pulseWidthSec", "chirpBandwidthHz"},
                )
            else:
                _add(
                    diagnostics,
                    "MISSING_FIELD",
                    f"configuration.waveform.{key}",
                    "required field is missing",
                )
        if all(
            key in waveform
            for key in ("chirpBandwidthHz", "chirpStartHz", "chirpStopHz")
        ):
            if (
                waveform["chirpStopHz"] - waveform["chirpStartHz"]
                != waveform["chirpBandwidthHz"]
            ):
                _add(
                    diagnostics,
                    "INCONSISTENT_RATE",
                    "configuration.waveform.chirpBandwidthHz",
                    "must equal chirpStopHz minus chirpStartHz",
                )

    scan = _field(value, "scan", "configuration.scan", diagnostics)
    if isinstance(scan, dict):
        _closed(
            scan,
            {"azimuthSectorDeg", "updatePeriodSec", "extensions"},
            "configuration.scan",
            diagnostics,
        )
        sector = _field(
            scan,
            "azimuthSectorDeg",
            "configuration.scan.azimuthSectorDeg",
            diagnostics,
        )
        _vector(sector, "configuration.scan.azimuthSectorDeg", 2, diagnostics)
        if isinstance(sector, list) and len(sector) == 2 and sector[0] >= sector[1]:
            _add(
                diagnostics,
                "VALUE_OUT_OF_RANGE",
                "configuration.scan.azimuthSectorDeg",
                "lower bound must be less than upper bound",
            )
        _required_number(
            scan,
            "updatePeriodSec",
            "configuration.scan.updatePeriodSec",
            diagnostics,
            positive=True,
        )

    blanking = _field(value, "blanking", "configuration.blanking", diagnostics)
    if isinstance(blanking, dict):
        _closed(
            blanking,
            {"transmitBlankingSec", "guardSec", "extensions"},
            "configuration.blanking",
            diagnostics,
        )
        for key in ("transmitBlankingSec", "guardSec"):
            _required_number(
                blanking,
                key,
                f"configuration.blanking.{key}",
                diagnostics,
                positive=True,
            )

    random_settings = _field(value, "random", "configuration.random", diagnostics)
    if isinstance(random_settings, dict):
        _closed(
            random_settings, {"seed", "extensions"}, "configuration.random", diagnostics
        )
        seed = random_settings.get("seed")
        _required_number(
            random_settings,
            "seed",
            "configuration.random.seed",
            diagnostics,
            integer=True,
        )
        if isinstance(seed, int) and seed < 0:
            _add(
                diagnostics,
                "VALUE_OUT_OF_RANGE",
                "configuration.random.seed",
                "must be non-negative",
            )

    ddc = _field(value, "ddc", "configuration.ddc", diagnostics)
    if isinstance(ddc, dict):
        _closed(
            ddc,
            {
                "complexIntermediateRateHz",
                "outputRateHz",
                "decimationFactors",
                "extensions",
            },
            "configuration.ddc",
            diagnostics,
        )
        if "decimationFactors" not in ddc:
            _add(
                diagnostics,
                "MISSING_FIELD",
                "configuration.ddc.decimationFactors",
                "required field is missing",
            )
        elif ddc["decimationFactors"] != [3, 4]:
            _add(
                diagnostics,
                "INCONSISTENT_RATE",
                "configuration.ddc.decimationFactors",
                "must equal [3, 4]",
            )
        intermediate = ddc.get("complexIntermediateRateHz")
        output = ddc.get("outputRateHz")
        adc_rate = value.get("adcSampleRateHz")
        for key in ("complexIntermediateRateHz", "outputRateHz"):
            _required_number(
                ddc, key, f"configuration.ddc.{key}", diagnostics, positive=True
            )
        if (
            isinstance(adc_rate, (int, float))
            and isinstance(intermediate, (int, float))
            and adc_rate / 3 != intermediate
        ):
            _add(
                diagnostics,
                "INCONSISTENT_RATE",
                "configuration.ddc.complexIntermediateRateHz",
                "must equal adcSampleRateHz / 3",
            )
        if (
            isinstance(intermediate, (int, float))
            and isinstance(output, (int, float))
            and intermediate / 4 != output
        ):
            _add(
                diagnostics,
                "INCONSISTENT_RATE",
                "configuration.ddc.outputRateHz",
                "must equal complexIntermediateRateHz / 4",
            )

    prfs = _field(value, "prfsHz", "configuration.prfsHz", diagnostics)
    pri_counts = _field(
        value, "priSampleCounts", "configuration.priSampleCounts", diagnostics
    )
    if not isinstance(prfs, list) or len(prfs) != 5:
        _add(
            diagnostics,
            "DIMENSION_MISMATCH",
            "configuration.prfsHz",
            "must contain five PRFs",
        )
    if not isinstance(pri_counts, list) or len(pri_counts) != 5:
        _add(
            diagnostics,
            "DIMENSION_MISMATCH",
            "configuration.priSampleCounts",
            "must contain five PRI tick counts",
        )
    if (
        isinstance(prfs, list)
        and isinstance(pri_counts, list)
        and len(prfs) == len(pri_counts)
    ):
        adc_rate = value.get("adcSampleRateHz")
        for index, (prf, pri) in enumerate(zip(prfs, pri_counts)):
            _number(prf, f"configuration.prfsHz[{index}]", diagnostics, positive=True)
            _number(
                pri,
                f"configuration.priSampleCounts[{index}]",
                diagnostics,
                positive=True,
                integer=True,
            )
            if (
                isinstance(adc_rate, (int, float))
                and isinstance(prf, (int, float))
                and isinstance(pri, int)
            ):
                expected = 12 * round(adc_rate / (12 * prf))
                if pri != expected:
                    _add(
                        diagnostics,
                        "INCONSISTENT_RATE",
                        f"configuration.priSampleCounts[{index}]",
                        "does not match the /12-aligned candidate rule",
                    )

    processing = _field(value, "processing", "configuration.processing", diagnostics)
    if isinstance(processing, dict):
        _closed(
            processing,
            {
                "maxInstrumentedRangeM",
                "rangeDomainM",
                "nearZeroDoppler",
                "cfar",
                "clustering",
                "ambiguity",
                "extensions",
            },
            "configuration.processing",
            diagnostics,
        )
        domain = _field(
            processing,
            "rangeDomainM",
            "configuration.processing.rangeDomainM",
            diagnostics,
        )
        if not isinstance(domain, list) or len(domain) != 2:
            _add(
                diagnostics,
                "DIMENSION_MISMATCH",
                "configuration.processing.rangeDomainM",
                "must contain two bounds",
            )
        elif domain != [6800, 100000]:
            _add(
                diagnostics,
                "VALUE_OUT_OF_RANGE",
                "configuration.processing.rangeDomainM",
                "must equal [6800, 100000]",
            )
        if "maxInstrumentedRangeM" not in processing:
            _add(
                diagnostics,
                "MISSING_FIELD",
                "configuration.processing.maxInstrumentedRangeM",
                "required field is missing",
            )
        elif processing["maxInstrumentedRangeM"] != 100000:
            _add(
                diagnostics,
                "VALUE_OUT_OF_RANGE",
                "configuration.processing.maxInstrumentedRangeM",
                "must equal 100000",
            )
        near_zero = _field(
            processing,
            "nearZeroDoppler",
            "configuration.processing.nearZeroDoppler",
            diagnostics,
        )
        if isinstance(near_zero, dict):
            _closed(
                near_zero,
                {"enabled", "cutoffMps", "extensions"},
                "configuration.processing.nearZeroDoppler",
                diagnostics,
            )
            if "enabled" not in near_zero:
                _add(
                    diagnostics,
                    "MISSING_FIELD",
                    "configuration.processing.nearZeroDoppler.enabled",
                    "required field is missing",
                )
            elif not isinstance(near_zero.get("enabled"), bool):
                _add(
                    diagnostics,
                    "TYPE_MISMATCH",
                    "configuration.processing.nearZeroDoppler.enabled",
                    "must be logical",
                )
            elif near_zero["enabled"]:
                _required_number(
                    near_zero,
                    "cutoffMps",
                    "configuration.processing.nearZeroDoppler.cutoffMps",
                    diagnostics,
                    positive=True,
                )
            elif "cutoffMps" in near_zero:
                _add(
                    diagnostics,
                    "VALUE_OUT_OF_RANGE",
                    "configuration.processing.nearZeroDoppler.cutoffMps",
                    "disabled fixtures must not invent a cutoff",
                )
        for key in ("cfar", "clustering", "ambiguity"):
            settings = _field(
                value=processing,
                key=key,
                path=f"configuration.processing.{key}",
                diagnostics=diagnostics,
            )
            if isinstance(settings, dict):
                _closed(
                    settings,
                    {"method", "extensions"},
                    f"configuration.processing.{key}",
                    diagnostics,
                )
                _text(
                    settings.get("method"),
                    f"configuration.processing.{key}.method",
                    diagnostics,
                )
    return diagnostics


def _validate_scenario(value: Any) -> list[dict[str, str]]:
    diagnostics: list[dict[str, str]] = []
    artifact = "scenario"
    _envelope(
        value, "radar.target-scenario", artifact, diagnostics, document_version="0.1.0"
    )
    if not isinstance(value, dict):
        return diagnostics
    _closed(
        value,
        {
            "schemaName",
            "schemaVersion",
            "documentVersion",
            "id",
            "createdUtc",
            "producer",
            "frame",
            "timeEpoch",
            "scanDurationSec",
            "targets",
            "extensions",
        },
        "scenario",
        diagnostics,
    )
    if "frame" not in value:
        _add(
            diagnostics,
            "MISSING_FIELD",
            "scenario.frame",
            "required field is missing",
        )
    else:
        _text(value["frame"], "scenario.frame", diagnostics)
    if value.get("frame") != "radar-centered" and "frame" in value:
        _add(
            diagnostics,
            "VALUE_OUT_OF_RANGE",
            "scenario.frame",
            "must equal radar-centered",
        )
    _required_text(value, "timeEpoch", "scenario.timeEpoch", diagnostics)
    _required_number(
        value,
        "scanDurationSec",
        "scenario.scanDurationSec",
        diagnostics,
        positive=True,
    )
    targets = _field(value, "targets", "scenario.targets", diagnostics)
    if not isinstance(targets, list):
        _add(diagnostics, "TYPE_MISMATCH", "scenario.targets", "must be an array")
        return diagnostics
    ids: set[str] = set()
    for index, target in enumerate(targets):
        path = f"scenario.targets[{index}]"
        if not isinstance(target, dict):
            _add(diagnostics, "TYPE_MISMATCH", path, "must be an object")
            continue
        _closed(
            target,
            {"id", "rcsM2", "positionM", "velocityMps", "extensions"},
            path,
            diagnostics,
        )
        target_id = target.get("id")
        _required_text(target, "id", f"{path}.id", diagnostics)
        if isinstance(target_id, str) and target_id in ids:
            _add(
                diagnostics,
                "DUPLICATE_ID",
                f"{path}.id",
                "target id must be unique within the scenario",
            )
        if isinstance(target_id, str):
            ids.add(target_id)
        rcs = _field(target, "rcsM2", f"{path}.rcsM2", diagnostics)
        position = _field(target, "positionM", f"{path}.positionM", diagnostics)
        velocity = _field(target, "velocityMps", f"{path}.velocityMps", diagnostics)
        if rcs is not None:
            _number(rcs, f"{path}.rcsM2", diagnostics, positive=True)
        if position is not None:
            _vector(position, f"{path}.positionM", 3, diagnostics)
        if velocity is not None:
            _vector(velocity, f"{path}.velocityMps", 3, diagnostics)
        if (
            isinstance(position, list)
            and len(position) == 3
            and all(finite_number(item) for item in position)
            and all(item == 0 for item in position)
        ):
            _add(
                diagnostics,
                "VALUE_OUT_OF_RANGE",
                f"{path}.positionM",
                "zero-range target positions are invalid",
            )
    return diagnostics


def _validate_detection_list(value: Any) -> list[dict[str, str]]:
    diagnostics: list[dict[str, str]] = []
    artifact = "detection-list"
    _envelope(value, "radar.detection-list", artifact, diagnostics)
    if not isinstance(value, dict):
        return diagnostics
    _closed(
        value,
        {
            "schemaName",
            "schemaVersion",
            "documentVersion",
            "id",
            "createdUtc",
            "producer",
            "configurationId",
            "testVectorId",
            "timeEpoch",
            "fixtureScope",
            "detections",
            "metadata",
            "extensions",
        },
        "detection-list",
        diagnostics,
    )
    for key in ("configurationId", "testVectorId", "timeEpoch", "fixtureScope"):
        _required_text(value, key, f"{artifact}.{key}", diagnostics)
    if "fixtureScope" in value:
        _fixture_scope(value["fixtureScope"], f"{artifact}.fixtureScope", diagnostics)
    detections = _field(value, "detections", f"{artifact}.detections", diagnostics)
    if not isinstance(detections, list):
        _add(
            diagnostics,
            "DIMENSION_MISMATCH",
            "detection-list.detections",
            "must be a row-oriented array",
        )
        return diagnostics
    ids: set[str] = set()
    for index, detection in enumerate(detections):
        path = f"detection-list.detections[{index}]"
        if not isinstance(detection, dict):
            _add(diagnostics, "TYPE_MISMATCH", path, "must be an object")
            continue
        detection_fields = {
            "detectionId",
            "rangeM",
            "radialVelocityMps",
            "azimuthDeg",
            "elevationDeg",
            "detectionStatistic",
            "clusterId",
            "prfEvidence",
            "ambiguityStatus",
            "extensions",
        }
        _closed(detection, detection_fields, path, diagnostics)
        for key in (
            "detectionId",
            "rangeM",
            "radialVelocityMps",
            "azimuthDeg",
            "elevationDeg",
            "detectionStatistic",
        ):
            if key not in detection:
                _add(
                    diagnostics,
                    "MISSING_FIELD",
                    f"{path}.{key}",
                    "required field is missing",
                )
        detection_id = detection.get("detectionId")
        _text(detection_id, f"{path}.detectionId", diagnostics)
        if isinstance(detection_id, str) and detection_id in ids:
            _add(
                diagnostics,
                "DUPLICATE_ID",
                f"{path}.detectionId",
                "detection id must be unique",
            )
        if isinstance(detection_id, str):
            ids.add(detection_id)
        for key in ("rangeM", "radialVelocityMps", "azimuthDeg", "elevationDeg"):
            _number(detection.get(key), f"{path}.{key}", diagnostics)
        range_value = detection.get("rangeM")
        if finite_number(range_value) and not 6800 <= range_value <= 100000:
            _add(
                diagnostics,
                "VALUE_OUT_OF_RANGE",
                f"{path}.rangeM",
                "must lie within the configured range domain [6800, 100000] m",
            )
        statistic = detection.get("detectionStatistic")
        if not isinstance(statistic, dict):
            _add(
                diagnostics,
                "TYPE_MISMATCH",
                f"{path}.detectionStatistic",
                "must be an object",
            )
        else:
            _validate_statistic(statistic, f"{path}.detectionStatistic", diagnostics)
    metadata = _field(value, "metadata", f"{artifact}.metadata", diagnostics)
    if not isinstance(metadata, dict):
        _add(
            diagnostics,
            "MISSING_FIELD",
            "detection-list.metadata",
            "required metadata object is missing",
        )
    else:
        _closed(
            metadata,
            {
                "methodStatus",
                "configurationSchemaVersion",
                "configurationDocumentVersion",
                "testVectorSchemaVersion",
                "testVectorDocumentVersion",
                "scanMidpointTick",
                "extensions",
            },
            "detection-list.metadata",
            diagnostics,
        )
        for key in ("configurationSchemaVersion", "testVectorSchemaVersion"):
            if key not in metadata:
                _add(
                    diagnostics,
                    "MISSING_FIELD",
                    f"detection-list.metadata.{key}",
                    "required field is missing",
                )
            else:
                _version(
                    metadata[key],
                    f"detection-list.metadata.{key}",
                    diagnostics,
                    DRAFT_SCHEMA_VERSION,
                )
        for key in ("configurationDocumentVersion", "testVectorDocumentVersion"):
            if key not in metadata:
                _add(
                    diagnostics,
                    "MISSING_FIELD",
                    f"detection-list.metadata.{key}",
                    "required field is missing",
                )
            else:
                _version(
                    metadata[key],
                    f"detection-list.metadata.{key}",
                    diagnostics,
                    EXPECTED_DOCUMENT_VERSION,
                )
        if value.get("fixtureScope") == "acceptance":
            if "scanMidpointTick" not in metadata:
                _add(
                    diagnostics,
                    "MISSING_FIELD",
                    "detection-list.metadata.scanMidpointTick",
                    "acceptance reports require a scan-midpoint tick",
                )
            else:
                _number(
                    metadata["scanMidpointTick"],
                    "detection-list.metadata.scanMidpointTick",
                    diagnostics,
                )
        if "methodStatus" not in metadata:
            _add(
                diagnostics,
                "MISSING_FIELD",
                "detection-list.metadata.methodStatus",
                "required field is missing",
            )
        elif _text(
            metadata["methodStatus"],
            "detection-list.metadata.methodStatus",
            diagnostics,
        ):
            if value.get("fixtureScope") == "acceptance" and metadata[
                "methodStatus"
            ].startswith("pending-"):
                _add(
                    diagnostics,
                    "METHOD_PENDING",
                    "detection-list.metadata.methodStatus",
                    "acceptance reports cannot use a pending method",
                )
            elif (
                value.get("fixtureScope") == "unit-only"
                and metadata.get("methodStatus") != "pending-wp7"
            ):
                _add(
                    diagnostics,
                    "METHOD_PENDING",
                    "detection-list.metadata.methodStatus",
                    "unit-only example must declare pending-wp7",
                )
    return diagnostics


def _is_shape(value: Any) -> TypeGuard[list[int]]:
    return isinstance(value, list) and all(
        isinstance(item, int) and not isinstance(item, bool) and item >= 0
        for item in value
    )


def _axis_centers(
    value: dict[str, Any],
    key: str,
    path: str,
    expected_length: int,
    diagnostics: list[dict[str, str]],
) -> None:
    if key not in value:
        _add(diagnostics, "MISSING_FIELD", path, "required field is missing")
        return
    centers = value[key]
    if not isinstance(centers, list):
        _add(diagnostics, "TYPE_MISMATCH", path, "must be an array")
        return
    if len(centers) != expected_length:
        _add(
            diagnostics,
            "DIMENSION_MISMATCH",
            path,
            "axis-center count must match the declared shape",
        )
    for index, center in enumerate(centers):
        _number(center, f"{path}[{index}]", diagnostics)


def _validate_cluster_record(
    record: Any,
    path: str,
    is_cluster: bool,
    diagnostics: list[dict[str, str]],
) -> None:
    if not isinstance(record, dict):
        _add(diagnostics, "TYPE_MISMATCH", path, "must be an object")
        return
    identifier = "clusterId" if is_cluster else "hypothesisId"
    required = (
        identifier,
        "rangeM",
        "radialVelocityMps",
        "supportMask",
        "validityMask",
        "sourceCellIds",
    )
    if is_cluster:
        required += ("hypothesisIds",)
    allowed = set(required) | {"extensions"}
    _closed(record, allowed, path, diagnostics)
    for key in required:
        if key not in record:
            _add(
                diagnostics,
                "MISSING_FIELD",
                f"{path}.{key}",
                "required field is missing",
            )
    identifier_value = record.get(identifier)
    if is_cluster:
        if not isinstance(identifier_value, str) or not identifier_value:
            _add(
                diagnostics,
                "TYPE_MISMATCH",
                f"{path}.{identifier}",
                "must be a non-empty string",
            )
    elif (
        not isinstance(identifier_value, int)
        or isinstance(identifier_value, bool)
        or identifier_value <= 0
    ):
        _add(
            diagnostics,
            "TYPE_MISMATCH",
            f"{path}.{identifier}",
            "must be a positive integer",
        )
    for key in ("rangeM", "radialVelocityMps"):
        scalar = record.get(key)
        if not isinstance(scalar, (int, float)) or isinstance(scalar, bool):
            _add(diagnostics, "TYPE_MISMATCH", f"{path}.{key}", "must be a number")
        elif not math.isfinite(scalar):
            _add(diagnostics, "NONFINITE", f"{path}.{key}", "must be finite")
    for key in ("supportMask", "validityMask"):
        mask = record.get(key)
        if not isinstance(mask, list) or len(mask) != 5:
            _add(
                diagnostics,
                "DIMENSION_MISMATCH",
                f"{path}.{key}",
                "must contain one value for each of five PRFs",
            )
        elif not all(isinstance(flag, bool) for flag in mask):
            _add(
                diagnostics,
                "TYPE_MISMATCH",
                f"{path}.{key}",
                "must contain logical values",
            )
    source_ids = record.get("sourceCellIds")
    if (
        not isinstance(source_ids, list)
        or not source_ids
        or not all(isinstance(item, str) and item for item in source_ids)
    ):
        _add(
            diagnostics,
            "TYPE_MISMATCH",
            f"{path}.sourceCellIds",
            "must be a non-empty string array",
        )
    if is_cluster:
        hypothesis_ids = record.get("hypothesisIds")
        if (
            not isinstance(hypothesis_ids, list)
            or not hypothesis_ids
            or not all(
                isinstance(item, int) and not isinstance(item, bool) and item > 0
                for item in hypothesis_ids
            )
        ):
            _add(
                diagnostics,
                "TYPE_MISMATCH",
                f"{path}.hypothesisIds",
                "must be a non-empty positive-integer array",
            )


def _validate_stage(stage: Any, index: int) -> list[dict[str, str]]:
    diagnostics: list[dict[str, str]] = []
    path = f"stages[{index}]"
    if not isinstance(stage, dict):
        _add(diagnostics, "TYPE_MISMATCH", path, "must be an object")
        return diagnostics
    required = (
        "schemaName",
        "schemaVersion",
        "documentVersion",
        "id",
        "stage",
        "createdUtc",
        "producer",
        "configurationId",
        "testVectorId",
        "timeEpoch",
        "sampleRateHz",
        "shape",
        "units",
        "channelMap",
        "metadata",
        "data",
        "fixtureScope",
        "sourceId",
        "sourceSchemaVersion",
        "sourceDocumentVersion",
    )
    for key in required:
        if key not in stage:
            _add(
                diagnostics,
                "MISSING_FIELD",
                f"{path}.{key}",
                "required field is missing",
            )
    _closed(
        stage,
        {
            "schemaName",
            "schemaVersion",
            "documentVersion",
            "id",
            "stage",
            "createdUtc",
            "producer",
            "configurationId",
            "testVectorId",
            "timeEpoch",
            "sampleRateHz",
            "shape",
            "units",
            "channelMap",
            "data",
            "metadata",
            "fixtureScope",
            "sourceId",
            "sourceSchemaVersion",
            "sourceDocumentVersion",
            "extensions",
        },
        path,
        diagnostics,
    )
    if stage.get("schemaName") != "radar.processing-intermediate":
        _add(
            diagnostics,
            "VALUE_OUT_OF_RANGE",
            f"{path}.schemaName",
            "must equal radar.processing-intermediate",
        )
    _version(
        stage.get("schemaVersion"),
        f"{path}.schemaVersion",
        diagnostics,
        DRAFT_SCHEMA_VERSION,
    )
    _version(
        stage.get("documentVersion"),
        f"{path}.documentVersion",
        diagnostics,
        EXPECTED_DOCUMENT_VERSION,
    )
    _version(
        stage.get("sourceSchemaVersion"),
        f"{path}.sourceSchemaVersion",
        diagnostics,
        DRAFT_SCHEMA_VERSION,
    )
    _version(
        stage.get("sourceDocumentVersion"),
        f"{path}.sourceDocumentVersion",
        diagnostics,
        EXPECTED_DOCUMENT_VERSION,
    )
    for key in (
        "id",
        "createdUtc",
        "producer",
        "configurationId",
        "testVectorId",
        "timeEpoch",
        "units",
        "fixtureScope",
        "sourceId",
    ):
        _text(stage.get(key), f"{path}.{key}", diagnostics)
    if "fixtureScope" in stage:
        _fixture_scope(stage["fixtureScope"], f"{path}.fixtureScope", diagnostics)
    _text(stage.get("stage"), f"{path}.stage", diagnostics)
    _text(stage.get("units"), f"{path}.units", diagnostics)
    if stage.get("channelMap") != "row-major-16x4":
        _add(
            diagnostics,
            "PROVENANCE_MISMATCH",
            f"{path}.channelMap",
            "must use the authoritative row-major-16x4 channel map",
        )
    stage_name = stage.get("stage")
    if stage_name not in STAGES:
        _add(
            diagnostics,
            "VALUE_OUT_OF_RANGE",
            f"{path}.stage",
            "unsupported processing seam",
        )
        return diagnostics
    _number(
        stage.get("sampleRateHz"), f"{path}.sampleRateHz", diagnostics, positive=True
    )
    shape = stage.get("shape")
    if not _is_shape(shape):
        _add(
            diagnostics,
            "DIMENSION_MISMATCH",
            f"{path}.shape",
            "must be a non-negative integer shape",
        )
        shape = []
    expected_dimensions = {
        "ddc": 2,
        "azimuth-beamformed": 2,
        "range": 3,
        "doppler": 3,
    }.get(stage_name, 2)
    if len(shape) != expected_dimensions:
        _add(
            diagnostics,
            "DIMENSION_MISMATCH",
            f"{path}.shape",
            f"{stage_name} shape must have {expected_dimensions} axes",
        )
    if (
        stage_name
        in {
            "angle",
            "candidate-list",
            "ambiguity-projection",
            "cfar",
            "fusion",
            "cluster",
        }
        and len(shape) == 2
        and shape[1] != 1
    ):
        _add(
            diagnostics,
            "DIMENSION_MISMATCH",
            f"{path}.shape",
            "row-oriented stage shape must be [N,1]",
        )
    expected_last = {"ddc": 64, "azimuth-beamformed": 4, "range": 4, "doppler": 4}.get(
        stage_name
    )
    if expected_last is not None and len(shape) >= 2 and shape[-1] != expected_last:
        _add(
            diagnostics,
            "DIMENSION_MISMATCH",
            f"{path}.shape",
            f"{stage_name} last axis must be {expected_last}",
        )
    metadata = stage.get("metadata")
    if not isinstance(metadata, dict):
        _add(
            diagnostics,
            "MISSING_FIELD",
            f"{path}.metadata",
            "required metadata object is missing",
        )
    else:
        _closed(
            metadata,
            {
                "axisNames",
                "fixtureSeed",
                "dataType",
                "azimuthLookIndex",
                "steeringConvention",
                "rangeBinCentersM",
                "dopplerBinCentersMps",
                "prfCount",
                "method",
                "hypothesisShape",
                "clusterShape",
                "extensions",
            },
            f"{path}.metadata",
            diagnostics,
        )
        axis_names = metadata.get("axisNames")
        if "axisNames" not in metadata:
            _add(
                diagnostics,
                "MISSING_FIELD",
                f"{path}.metadata.axisNames",
                "required field is missing",
            )
        elif not isinstance(axis_names, list):
            _add(
                diagnostics,
                "TYPE_MISMATCH",
                f"{path}.metadata.axisNames",
                "must be an array of axis names",
            )
        elif len(axis_names) != len(shape):
            _add(
                diagnostics,
                "DIMENSION_MISMATCH",
                f"{path}.metadata.axisNames",
                "axis name count must equal shape rank",
            )
        else:
            for axis_index, axis_name in enumerate(axis_names):
                _text(
                    axis_name,
                    f"{path}.metadata.axisNames[{axis_index}]",
                    diagnostics,
                )
        if "fixtureSeed" not in metadata:
            _add(
                diagnostics,
                "MISSING_FIELD",
                f"{path}.metadata.fixtureSeed",
                "required field is missing",
            )
        else:
            _number(
                metadata["fixtureSeed"],
                f"{path}.metadata.fixtureSeed",
                diagnostics,
                integer=True,
            )
        if stage_name in {"ddc", "azimuth-beamformed", "range", "doppler"}:
            if "dataType" not in metadata:
                _add(
                    diagnostics,
                    "MISSING_FIELD",
                    f"{path}.metadata.dataType",
                    "required field is missing",
                )
            else:
                _text(metadata["dataType"], f"{path}.metadata.dataType", diagnostics)
        if stage_name in {"azimuth-beamformed", "doppler"}:
            if "azimuthLookIndex" not in metadata:
                _add(
                    diagnostics,
                    "MISSING_FIELD",
                    f"{path}.metadata.azimuthLookIndex",
                    "commanded look index is required",
                )
            else:
                _number(
                    metadata["azimuthLookIndex"],
                    f"{path}.metadata.azimuthLookIndex",
                    diagnostics,
                    positive=True,
                    integer=True,
                )
        if stage_name == "azimuth-beamformed":
            if "steeringConvention" not in metadata:
                _add(
                    diagnostics,
                    "MISSING_FIELD",
                    f"{path}.metadata.steeringConvention",
                    "steering convention is required",
                )
            else:
                _text(
                    metadata["steeringConvention"],
                    f"{path}.metadata.steeringConvention",
                    diagnostics,
                )
                if metadata["steeringConvention"] != "conjugate-sum":
                    _add(
                        diagnostics,
                        "VALUE_OUT_OF_RANGE",
                        f"{path}.metadata.steeringConvention",
                        "must equal conjugate-sum",
                    )
        if stage_name == "doppler":
            for key, axis in (("rangeBinCentersM", 0), ("dopplerBinCentersMps", 1)):
                expected = shape[axis] if len(shape) > axis else 0
                _axis_centers(
                    metadata,
                    key,
                    f"{path}.metadata.{key}",
                    expected,
                    diagnostics,
                )
        if stage_name == "range":
            expected = shape[0] if shape else 0
            _axis_centers(
                metadata,
                "rangeBinCentersM",
                f"{path}.metadata.rangeBinCentersM",
                expected,
                diagnostics,
            )
        if stage_name == "ambiguity-projection":
            if "prfCount" not in metadata:
                _add(
                    diagnostics,
                    "MISSING_FIELD",
                    f"{path}.metadata.prfCount",
                    "required field is missing",
                )
            elif (
                _number(
                    metadata["prfCount"],
                    f"{path}.metadata.prfCount",
                    diagnostics,
                    integer=True,
                )
                and metadata["prfCount"] != 5
            ):
                _add(
                    diagnostics,
                    "VALUE_OUT_OF_RANGE",
                    f"{path}.metadata.prfCount",
                    "must equal the five configured PRF layers",
                )
        if stage_name in {"cfar", "fusion", "cluster"}:
            if "method" not in metadata:
                _add(
                    diagnostics,
                    "MISSING_FIELD",
                    f"{path}.metadata.method",
                    "required method is missing",
                )
            else:
                _text(metadata["method"], f"{path}.metadata.method", diagnostics)
        if metadata.get("method") == "pending-wp6e":
            _add(
                diagnostics,
                "METHOD_PENDING",
                f"{path}.metadata.method",
                "ambiguity method is pending WP6e",
            )
        if stage.get("fixtureScope") == "acceptance" and metadata.get("method") in {
            "pending-wp6e",
            "pending-wp7",
        }:
            _add(
                diagnostics,
                "METHOD_PENDING",
                f"{path}.metadata.method",
                "acceptance fixtures cannot use a pending method",
            )

    data = stage.get("data")
    if isinstance(data, dict) and data.get("encoding") == "zero-fill":
        _closed(
            data,
            {"encoding", "shape", "extensions"},
            f"{path}.data",
            diagnostics,
        )
        if "shape" not in data:
            _add(
                diagnostics,
                "MISSING_FIELD",
                f"{path}.data.shape",
                "required field is missing",
            )
        elif data.get("shape") != shape:
            _add(
                diagnostics,
                "DIMENSION_MISMATCH",
                f"{path}.data.shape",
                "encoded data shape must equal envelope shape",
            )
    elif isinstance(data, list):
        if len(shape) >= 1 and len(data) != shape[0]:
            _add(
                diagnostics,
                "DIMENSION_MISMATCH",
                f"{path}.data",
                "row count must equal the first shape axis",
            )
    elif stage_name == "cluster" and isinstance(data, dict):
        if "hypotheses" not in data:
            _add(
                diagnostics,
                "MISSING_FIELD",
                f"{path}.data.hypotheses",
                "required field is missing",
            )
        if "clusters" not in data:
            _add(
                diagnostics,
                "MISSING_FIELD",
                f"{path}.data.clusters",
                "required field is missing",
            )
        _closed(
            data, {"hypotheses", "clusters", "extensions"}, f"{path}.data", diagnostics
        )
        for key in ("hypotheses", "clusters"):
            if not isinstance(data.get(key), list):
                _add(
                    diagnostics,
                    "TYPE_MISMATCH",
                    f"{path}.data.{key}",
                    "must be an array",
                )
    else:
        _add(
            diagnostics,
            "TYPE_MISMATCH",
            f"{path}.data",
            "unsupported data representation",
        )

    if (
        stage_name == "cluster"
        and isinstance(data, dict)
        and isinstance(metadata, dict)
    ):
        hypotheses = data.get("hypotheses")
        clusters = data.get("clusters")
        hypothesis_shape = metadata.get("hypothesisShape")
        cluster_shape = metadata.get("clusterShape")
        for key, declared, records in (
            ("hypothesisShape", hypothesis_shape, hypotheses),
            ("clusterShape", cluster_shape, clusters),
        ):
            shape_path = f"{path}.metadata.{key}"
            if key not in metadata:
                _add(
                    diagnostics,
                    "MISSING_FIELD",
                    shape_path,
                    "required field is missing",
                )
            elif not _is_shape(declared) or len(declared) != 2 or declared[1] != 1:
                _add(
                    diagnostics,
                    "DIMENSION_MISMATCH",
                    shape_path,
                    "must be an [N,1] row-oriented shape",
                )
            elif isinstance(records, list) and len(records) != declared[0]:
                data_key = "hypotheses" if key == "hypothesisShape" else "clusters"
                data_path = f"{path}.data.{data_key}"
                _add(
                    diagnostics,
                    "DIMENSION_MISMATCH",
                    data_path,
                    "record count must equal the declared [N,1] shape",
                )
        if (
            _is_shape(shape)
            and len(shape) == 2
            and shape[1] == 1
            and isinstance(clusters, list)
            and isinstance(cluster_shape, list)
            and len(cluster_shape) == 2
            and cluster_shape[1] == 1
            and shape[0] != len(clusters)
        ):
            _add(
                diagnostics,
                "DIMENSION_MISMATCH",
                f"{path}.shape",
                "cluster envelope shape must equal the cluster record count",
            )
        if isinstance(hypotheses, list):
            for row, record in enumerate(hypotheses):
                _validate_cluster_record(
                    record, f"{path}.data.hypotheses[{row}]", False, diagnostics
                )
        if isinstance(clusters, list):
            for row, record in enumerate(clusters):
                _validate_cluster_record(
                    record, f"{path}.data.clusters[{row}]", True, diagnostics
                )
        if isinstance(hypotheses, list) and isinstance(clusters, list):
            hypothesis_ids: set[int] = set()
            for record in hypotheses:
                if not isinstance(record, dict):
                    continue
                hypothesis_id = record.get("hypothesisId")
                if (
                    isinstance(hypothesis_id, int)
                    and not isinstance(hypothesis_id, bool)
                    and hypothesis_id > 0
                ):
                    hypothesis_ids.add(hypothesis_id)
            for row, cluster in enumerate(clusters):
                if not isinstance(cluster, dict):
                    continue
                references = cluster.get("hypothesisIds")
                if (
                    isinstance(references, list)
                    and all(
                        isinstance(reference, int)
                        and not isinstance(reference, bool)
                        and reference > 0
                        for reference in references
                    )
                    and any(reference not in hypothesis_ids for reference in references)
                ):
                    _add(
                        diagnostics,
                        "PROVENANCE_MISMATCH",
                        f"{path}.data.clusters[{row}].hypothesisIds",
                        "all hypothesis references must resolve within the stage",
                    )

    if stage_name == "ambiguity-projection" and isinstance(data, list):
        for row, item in enumerate(data):
            row_path = f"{path}.data[{row}]"
            if isinstance(item, dict):
                _closed(
                    item,
                    {
                        "hypothesisId",
                        "rangeM",
                        "radialVelocityMps",
                        "validityMask",
                        "sourceCellId",
                        "extensions",
                    },
                    row_path,
                    diagnostics,
                )
            if (
                not isinstance(item, dict)
                or not isinstance(item.get("validityMask"), list)
                or len(item["validityMask"]) != 5
            ):
                _add(
                    diagnostics,
                    "DIMENSION_MISMATCH",
                    f"{row_path}.validityMask",
                    "must contain one eligibility value for each of five PRFs",
                )
            elif not all(isinstance(flag, bool) for flag in item["validityMask"]):
                _add(
                    diagnostics,
                    "TYPE_MISMATCH",
                    f"{row_path}.validityMask",
                    "must contain logical eligibility values",
                )
            if isinstance(item, dict):
                for key in (
                    "hypothesisId",
                    "rangeM",
                    "radialVelocityMps",
                    "sourceCellId",
                ):
                    if key not in item:
                        _add(
                            diagnostics,
                            "MISSING_FIELD",
                            f"{row_path}.{key}",
                            "required field is missing",
                        )
                hypothesis_id = item.get("hypothesisId")
                if (
                    not isinstance(hypothesis_id, int)
                    or isinstance(hypothesis_id, bool)
                    or hypothesis_id <= 0
                ):
                    _add(
                        diagnostics,
                        "TYPE_MISMATCH",
                        f"{row_path}.hypothesisId",
                        "must be a positive integer",
                    )
                for key in ("rangeM", "radialVelocityMps"):
                    scalar = item.get(key)
                    _number(scalar, f"{row_path}.{key}", diagnostics)
                if not isinstance(item.get("sourceCellId"), str) or not item.get(
                    "sourceCellId"
                ):
                    _add(
                        diagnostics,
                        "TYPE_MISMATCH",
                        f"{row_path}.sourceCellId",
                        "must be a non-empty string",
                    )
    if stage_name == "candidate-list" and isinstance(data, list):
        candidate_ids: set[int] = set()
        for row, item in enumerate(data):
            row_path = f"{path}.data[{row}]"
            if not isinstance(item, dict):
                _add(diagnostics, "TYPE_MISMATCH", row_path, "must be an object")
                continue
            fields = (
                "candidateId",
                "prfIndex",
                "azimuthLookIndex",
                "elevationLookIndex",
                "rangeM",
                "foldedVelocityMps",
                "statistic",
                "sourceId",
            )
            _closed(item, set(fields) | {"extensions"}, row_path, diagnostics)
            for key in fields:
                if key not in item:
                    _add(
                        diagnostics,
                        "MISSING_FIELD",
                        f"{row_path}.{key}",
                        "required field is missing",
                    )
            candidate_id = item.get("candidateId")
            if (
                not isinstance(candidate_id, int)
                or isinstance(candidate_id, bool)
                or candidate_id <= 0
            ):
                _add(
                    diagnostics,
                    "TYPE_MISMATCH",
                    f"{row_path}.candidateId",
                    "must be a positive integer",
                )
            elif candidate_id in candidate_ids:
                _add(
                    diagnostics,
                    "DUPLICATE_ID",
                    f"{row_path}.candidateId",
                    "candidate id must be unique",
                )
            else:
                candidate_ids.add(candidate_id)
            for key in ("prfIndex", "azimuthLookIndex", "elevationLookIndex"):
                scalar = item.get(key)
                if (
                    not isinstance(scalar, int)
                    or isinstance(scalar, bool)
                    or scalar <= 0
                ):
                    if (
                        key == "prfIndex"
                        and isinstance(scalar, int)
                        and not isinstance(scalar, bool)
                    ):
                        _add(
                            diagnostics,
                            "VALUE_OUT_OF_RANGE",
                            f"{row_path}.{key}",
                            "must identify one of the five configured PRFs",
                        )
                    else:
                        _add(
                            diagnostics,
                            "TYPE_MISMATCH",
                            f"{row_path}.{key}",
                            "must be a positive integer",
                        )
                elif key == "prfIndex" and not 1 <= scalar <= 5:
                    _add(
                        diagnostics,
                        "VALUE_OUT_OF_RANGE",
                        f"{row_path}.{key}",
                        "must identify one of the five configured PRFs",
                    )
            for key in ("rangeM", "foldedVelocityMps"):
                scalar = item.get(key)
                if not isinstance(scalar, (int, float)) or isinstance(scalar, bool):
                    _add(
                        diagnostics,
                        "TYPE_MISMATCH",
                        f"{row_path}.{key}",
                        "must be a finite number",
                    )
                elif not math.isfinite(scalar):
                    _add(
                        diagnostics,
                        "NONFINITE",
                        f"{row_path}.{key}",
                        "must be finite",
                    )
            _validate_statistic(
                item.get("statistic"), f"{row_path}.statistic", diagnostics
            )
            if not isinstance(item.get("sourceId"), str) or not item.get("sourceId"):
                _add(
                    diagnostics,
                    "TYPE_MISMATCH",
                    f"{row_path}.sourceId",
                    "must be a non-empty string",
                )
    if stage_name == "fusion" and isinstance(data, list):
        for row, item in enumerate(data):
            row_path = f"{path}.data[{row}]"
            if not isinstance(item, dict):
                _add(
                    diagnostics,
                    "TYPE_MISMATCH",
                    row_path,
                    "must be an object",
                )
                continue
            fields = (
                "validityMask",
                "supportMask",
                "voteCount",
                "voteThreshold",
                "residual",
                "ambiguityStatus",
                "sourceCellIds",
                "hypothesisId",
                "rangeM",
                "radialVelocityMps",
            )
            _closed(item, set(fields) | {"extensions"}, row_path, diagnostics)
            for key in fields:
                if key not in item:
                    _add(
                        diagnostics,
                        "MISSING_FIELD",
                        f"{row_path}.{key}",
                        "required field is missing",
                    )
            for key in ("validityMask", "supportMask"):
                if not isinstance(item.get(key), list) or len(item[key]) != 5:
                    _add(
                        diagnostics,
                        "DIMENSION_MISMATCH",
                        f"{row_path}.{key}",
                        "must contain one value for each of five PRFs",
                    )
                elif not all(isinstance(flag, bool) for flag in item[key]):
                    _add(
                        diagnostics,
                        "TYPE_MISMATCH",
                        f"{row_path}.{key}",
                        "must contain logical values",
                    )
            if (
                isinstance(item.get("validityMask"), list)
                and isinstance(item.get("supportMask"), list)
                and len(item["validityMask"]) == len(item["supportMask"]) == 5
                and all(
                    isinstance(flag, bool)
                    for flag in item["validityMask"] + item["supportMask"]
                )
                and any(
                    supported and not valid
                    for supported, valid in zip(
                        item["supportMask"], item["validityMask"]
                    )
                )
            ):
                _add(
                    diagnostics,
                    "VALUE_OUT_OF_RANGE",
                    f"{row_path}.supportMask",
                    "supportMask cannot contain support for an invalid PRF",
                )
            for key in ("voteCount", "voteThreshold"):
                scalar = item.get(key)
                if (
                    not isinstance(scalar, int)
                    or isinstance(scalar, bool)
                    or scalar < 0
                ):
                    _add(
                        diagnostics,
                        "TYPE_MISMATCH",
                        f"{row_path}.{key}",
                        "must be a non-negative integer",
                    )
            for key in ("hypothesisId",):
                scalar = item.get(key)
                if (
                    not isinstance(scalar, int)
                    or isinstance(scalar, bool)
                    or scalar <= 0
                ):
                    _add(
                        diagnostics,
                        "TYPE_MISMATCH",
                        f"{row_path}.{key}",
                        "must be a positive integer",
                    )
            for key in ("rangeM", "radialVelocityMps", "residual"):
                _number(item.get(key), f"{row_path}.{key}", diagnostics)
            _text(
                item.get("ambiguityStatus"), f"{row_path}.ambiguityStatus", diagnostics
            )
            source_ids = item.get("sourceCellIds")
            if (
                not isinstance(source_ids, list)
                or not source_ids
                or not all(
                    isinstance(source_id, str) and source_id for source_id in source_ids
                )
            ):
                _add(
                    diagnostics,
                    "TYPE_MISMATCH",
                    f"{row_path}.sourceCellIds",
                    "must be a non-empty string array",
                )
            if (
                isinstance(item.get("voteThreshold"), int)
                and item["voteThreshold"] != 3
            ):
                _add(
                    diagnostics,
                    "VALUE_OUT_OF_RANGE",
                    f"{row_path}.voteThreshold",
                    "full-domain fusion baseline must use a 3-of-5 threshold",
                )
            if (
                isinstance(item.get("supportMask"), list)
                and isinstance(item.get("voteCount"), int)
                and all(isinstance(flag, bool) for flag in item["supportMask"])
                and item["voteCount"] != sum(item["supportMask"])
            ):
                _add(
                    diagnostics,
                    "VALUE_OUT_OF_RANGE",
                    f"{row_path}.voteCount",
                    "must equal the number of true supportMask values",
                )
    if stage_name == "cfar" and isinstance(data, list):
        for row, item in enumerate(data):
            row_path = f"{path}.data[{row}]"
            if isinstance(item, dict):
                fields = (
                    "prfIndex",
                    "azimuthLookIndex",
                    "elevationLookIndex",
                    "rangeBin",
                    "dopplerBin",
                    "sourceCellId",
                    "statistic",
                    "threshold",
                    "pass",
                    "decisionState",
                )
                _closed(item, set(fields) | {"extensions"}, row_path, diagnostics)
                for key in fields:
                    if key not in item:
                        _add(
                            diagnostics,
                            "MISSING_FIELD",
                            f"{row_path}.{key}",
                            "required field is missing",
                        )
                for key in (
                    "prfIndex",
                    "azimuthLookIndex",
                    "elevationLookIndex",
                    "rangeBin",
                    "dopplerBin",
                ):
                    scalar = item.get(key)
                    if (
                        not isinstance(scalar, int)
                        or isinstance(scalar, bool)
                        or scalar <= 0
                    ):
                        if (
                            key == "prfIndex"
                            and isinstance(scalar, int)
                            and not isinstance(scalar, bool)
                        ):
                            _add(
                                diagnostics,
                                "VALUE_OUT_OF_RANGE",
                                f"{row_path}.{key}",
                                "must identify one of the five configured PRFs",
                            )
                        else:
                            _add(
                                diagnostics,
                                "TYPE_MISMATCH",
                                f"{row_path}.{key}",
                                "must be a positive integer",
                            )
                    elif key == "prfIndex" and scalar > 5:
                        _add(
                            diagnostics,
                            "VALUE_OUT_OF_RANGE",
                            f"{row_path}.{key}",
                            "must identify one of the five configured PRFs",
                        )
                _text(item.get("sourceCellId"), f"{row_path}.sourceCellId", diagnostics)
                if "threshold" in item and (
                    not isinstance(item["threshold"], (int, float))
                    or isinstance(item["threshold"], bool)
                    or not math.isfinite(item["threshold"])
                ):
                    code = (
                        "NONFINITE"
                        if isinstance(item["threshold"], (int, float))
                        and not isinstance(item["threshold"], bool)
                        and not math.isfinite(item["threshold"])
                        else "TYPE_MISMATCH"
                    )
                    _add(
                        diagnostics,
                        code,
                        f"{row_path}.threshold",
                        "must be a finite number",
                    )
                _validate_statistic(
                    item.get("statistic"), f"{row_path}.statistic", diagnostics
                )
            else:
                _add(diagnostics, "TYPE_MISMATCH", row_path, "must be an object")
            if isinstance(item, dict) and item.get("decisionState") not in {
                "pass",
                "fail",
                "invalid",
            }:
                _add(
                    diagnostics,
                    "VALUE_OUT_OF_RANGE",
                    f"{row_path}.decisionState",
                    "must be pass, fail, or invalid",
                )
            if isinstance(item, dict) and not isinstance(item.get("pass"), bool):
                _add(
                    diagnostics,
                    "TYPE_MISMATCH",
                    f"{row_path}.pass",
                    "must be logical",
                )
            if (
                isinstance(item, dict)
                and isinstance(item.get("pass"), bool)
                and item.get("decisionState") in {"pass", "fail", "invalid"}
                and item["pass"] != (item["decisionState"] == "pass")
            ):
                _add(
                    diagnostics,
                    "VALUE_OUT_OF_RANGE",
                    f"{row_path}.pass",
                    "must agree with decisionState",
                )
    if stage_name == "angle" and isinstance(data, list):
        for row, item in enumerate(data):
            row_path = f"{path}.data[{row}]"
            if not isinstance(item, dict):
                _add(diagnostics, "TYPE_MISMATCH", row_path, "must be an object")
                continue
            _closed(
                item,
                {
                    "rangeM",
                    "radialVelocityMps",
                    "azimuthDeg",
                    "elevationDeg",
                    "statistic",
                    "extensions",
                },
                row_path,
                diagnostics,
            )
            for key in (
                "rangeM",
                "radialVelocityMps",
                "azimuthDeg",
                "elevationDeg",
                "statistic",
            ):
                if key not in item:
                    _add(
                        diagnostics,
                        "MISSING_FIELD",
                        f"{row_path}.{key}",
                        "required field is missing",
                    )
            for key in ("rangeM", "radialVelocityMps", "azimuthDeg", "elevationDeg"):
                scalar = item.get(key)
                _number(scalar, f"{row_path}.{key}", diagnostics)
            _validate_statistic(
                item.get("statistic"), f"{row_path}.statistic", diagnostics
            )
    return diagnostics


def _validate_processing(value: Any) -> list[dict[str, str]]:
    diagnostics: list[dict[str, str]] = []
    if not isinstance(value, dict):
        _add(
            diagnostics,
            "TYPE_MISMATCH",
            "processing-fixtures",
            "root must be an object",
        )
        return diagnostics
    required = (
        "schemaName",
        "schemaVersion",
        "documentVersion",
        "id",
        "createdUtc",
        "producer",
        "fixtureScope",
        "stages",
    )
    for key in required:
        if key not in value:
            _add(
                diagnostics,
                "MISSING_FIELD",
                f"processing-fixtures.{key}",
                "required field is missing",
            )
    if value.get("schemaName") != "radar.processing-fixtures":
        _add(
            diagnostics,
            "VALUE_OUT_OF_RANGE",
            "processing-fixtures.schemaName",
            "must equal radar.processing-fixtures",
        )
    _closed(
        value,
        {
            "schemaName",
            "schemaVersion",
            "documentVersion",
            "id",
            "createdUtc",
            "producer",
            "fixtureScope",
            "stages",
            "extensions",
        },
        "processing-fixtures",
        diagnostics,
    )
    _version(
        value.get("schemaVersion"),
        "processing-fixtures.schemaVersion",
        diagnostics,
        DRAFT_SCHEMA_VERSION,
    )
    _version(
        value.get("documentVersion"),
        "processing-fixtures.documentVersion",
        diagnostics,
        EXPECTED_DOCUMENT_VERSION,
    )
    for key in ("id", "createdUtc", "producer", "fixtureScope"):
        _text(value.get(key), f"processing-fixtures.{key}", diagnostics)
    if "fixtureScope" in value:
        _fixture_scope(
            value["fixtureScope"], "processing-fixtures.fixtureScope", diagnostics
        )
    stages = value.get("stages")
    if not isinstance(stages, list):
        _add(
            diagnostics,
            "TYPE_MISMATCH",
            "processing-fixtures.stages",
            "must be an array",
        )
        return diagnostics
    names = [stage.get("stage") for stage in stages if isinstance(stage, dict)]
    for required_stage in STAGES:
        if required_stage not in names:
            _add(
                diagnostics,
                "MISSING_FIELD",
                f"processing-fixtures.stages.{required_stage}",
                "canonical stage is missing",
            )
    for index, stage in enumerate(stages):
        diagnostics.extend(_validate_stage(stage, index))
    for index, stage in enumerate(stages):
        if not isinstance(stage, dict):
            continue
        if index > 0 and isinstance(stages[0], dict):
            reference = stages[0]
            for key in ("configurationId", "testVectorId", "timeEpoch"):
                if stage.get(key) != reference.get(key):
                    _add(
                        diagnostics,
                        "PROVENANCE_MISMATCH",
                        f"stages[{index}].{key}",
                        "must match the first stage provenance for the "
                        "processing fixture",
                    )
        expected_source = (
            stage.get("testVectorId") if index == 0 else stages[index - 1].get("id")
        )
        if stage.get("sourceId") != expected_source:
            _add(
                diagnostics,
                "PROVENANCE_MISMATCH",
                f"stages[{index}].sourceId",
                f"must identify the preceding stage or test vector ({expected_source})",
            )
        if index > 0 and isinstance(stages[index - 1], dict):
            previous = stages[index - 1]
            if stage.get("sourceSchemaVersion") != previous.get("schemaVersion"):
                _add(
                    diagnostics,
                    "PROVENANCE_MISMATCH",
                    f"stages[{index}].sourceSchemaVersion",
                    "must match the source stage schema version",
                )
            if stage.get("sourceDocumentVersion") != previous.get("documentVersion"):
                _add(
                    diagnostics,
                    "PROVENANCE_MISMATCH",
                    f"stages[{index}].sourceDocumentVersion",
                    "must match the source stage document version",
                )
    return diagnostics


def _validate_compatibility(value: Any) -> list[dict[str, str]]:
    diagnostics: list[dict[str, str]] = []
    _envelope(value, "radar.compatibility", "compatibility", diagnostics)
    if not isinstance(value, dict):
        return diagnostics
    _closed(
        value,
        {
            "schemaName",
            "schemaVersion",
            "documentVersion",
            "id",
            "createdUtc",
            "producer",
            "consumerSchemaVersion",
            "producerSchemaVersion",
            "migration",
            "acceptedMajor",
            "extensions",
        },
        "compatibility",
        diagnostics,
    )
    for key in ("consumerSchemaVersion", "producerSchemaVersion"):
        _version(value.get(key), f"compatibility.{key}", diagnostics)
    accepted = value.get("acceptedMajor")
    if (
        _number(accepted, "compatibility.acceptedMajor", diagnostics, integer=True)
        and accepted != 1
    ):
        _add(
            diagnostics,
            "VERSION_MISMATCH",
            "compatibility.acceptedMajor",
            "must accept schema major version 1",
        )
    _required_text(value, "migration", "compatibility.migration", diagnostics)
    if isinstance(value.get("consumerSchemaVersion"), str) and value[
        "consumerSchemaVersion"
    ].startswith("2."):
        _add(
            diagnostics,
            "VERSION_MISMATCH",
            "compatibility.consumerSchemaVersion",
            "major schema mismatch must be rejected",
        )
    if isinstance(value.get("producerSchemaVersion"), str) and value[
        "producerSchemaVersion"
    ].startswith("2."):
        _add(
            diagnostics,
            "VERSION_MISMATCH",
            "compatibility.producerSchemaVersion",
            "major schema mismatch must be rejected",
        )
    return diagnostics


def read_json_artifact(name: str) -> Any:
    """Read one canonical JSON artifact with strict non-finite rejection."""

    path = EXAMPLES / name
    with path.open(encoding="utf-8") as stream:
        return json.load(
            stream,
            parse_constant=lambda token: (_ for _ in ()).throw(
                ValueError(f"nonfinite JSON number: {token}")
            ),
        )


def read_example(name: str) -> dict[str, Any]:
    """Backward-compatible loader for the original checker seam."""

    value = read_json_artifact(name)
    if not isinstance(value, dict):
        raise ValueError(f"{name}: root must be an object")
    return value


def finite_number(value: object) -> TypeGuard[int | float]:
    """Return whether a JSON-compatible value is a finite scalar number."""

    return (
        isinstance(value, (int, float))
        and not isinstance(value, bool)
        and math.isfinite(value)
    )


def _artifact_kind(name: str, value: Any) -> str:
    if name == "configuration.json":
        return "configuration"
    if name == "scenario.json":
        return "scenario"
    if name == "empty-detection-list.json":
        return "detection-list"
    if name == "compatibility.json":
        return "compatibility"
    if name in {"processing-intermediates.json", "empty-processing-intermediates.json"}:
        return "processing"
    schema_name = value.get("schemaName") if isinstance(value, dict) else None
    if not isinstance(schema_name, str):
        return "unknown"
    return {
        "radar.configuration": "configuration",
        "radar.target-scenario": "scenario",
        "radar.detection-list": "detection-list",
        "radar.compatibility": "compatibility",
        "radar.processing-fixtures": "processing",
    }.get(schema_name, "unknown")


def check_artifact(value: Any, kind: str, artifact: str = "artifact") -> dict[str, Any]:
    """Validate an in-memory artifact and return structured diagnostics."""

    validators = {
        "configuration": _validate_configuration,
        "scenario": _validate_scenario,
        "detection-list": _validate_detection_list,
        "processing": _validate_processing,
        "compatibility": _validate_compatibility,
    }
    validator = validators.get(kind)
    if validator is None:
        return _report(
            artifact,
            [
                diagnostic(
                    "TYPE_MISMATCH", artifact, f"unsupported artifact kind {kind}"
                )
            ],
        )
    diagnostics = validator(value)
    prefixes = {
        "configuration": "configuration.",
        "scenario": "scenario.",
        "detection-list": "detection-list.",
        "compatibility": "compatibility.",
        "processing": "processing-fixtures.",
    }
    prefix = prefixes.get(kind, "")
    if prefix:
        for item in diagnostics:
            if item["path"].startswith(prefix):
                item["path"] = item["path"][len(prefix) :]
    return _report(artifact, diagnostics)


def _tokens(path: str) -> list[str | int]:
    tokens: list[str | int] = []
    for part in path.split("."):
        match = re.fullmatch(r"([^\[]+)(?:\[(\d+)\])?", part)
        if match is None:
            raise ValueError(f"unsupported mutation path: {path}")
        tokens.append(match.group(1))
        if match.group(2) is not None:
            tokens.append(int(match.group(2)))
    return tokens


def _resolve(container: Any, tokens: list[str | int]) -> tuple[Any, str | int]:
    current = container
    for token in tokens[:-1]:
        current = current[token]
    return current, tokens[-1]


def apply_mutation(base: Any, mutation: dict[str, Any] | None) -> Any:
    """Apply one manifest mutation to a deep copy of a JSON artifact."""

    value = copy.deepcopy(base)
    if mutation is None:
        return value
    operation = mutation["operation"]
    if operation == "duplicate":
        source_parent, source_key = _resolve(value, _tokens(mutation["path"]))
        value[mutation["appendPath"]].append(copy.deepcopy(source_parent[source_key]))
        return value
    parent, key = _resolve(value, _tokens(mutation["path"]))
    if operation in {"replace", "reshape"}:
        parent[key] = copy.deepcopy(mutation["value"])
    elif operation == "remove":
        del parent[key]
    else:
        raise ValueError(f"unsupported mutation operation: {operation}")
    return value


def run_manifest() -> list[dict[str, Any]]:
    """Run every executable JSON manifest row and return row-level reports."""

    manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    results: list[dict[str, Any]] = []
    for fixture in manifest["fixtures"]:
        if fixture.get("tool") == "matlab" or fixture["expected"] == "not-applicable":
            results.append(
                {"id": fixture["id"], "status": "skipped", "fixture": fixture}
            )
            continue
        base = read_json_artifact(fixture["baseArtifact"])
        mutated = apply_mutation(base, fixture.get("mutation"))
        report = check_artifact(
            mutated,
            _artifact_kind(fixture["baseArtifact"], base),
            fixture["baseArtifact"],
        )
        results.append(
            {
                "id": fixture["id"],
                "status": report["status"],
                "report": report,
                "fixture": fixture,
            }
        )
    return results


def check() -> dict[str, Any]:
    """Check canonical examples and all executable manifest rows."""

    canonical_reports = []
    canonical_names = (
        "configuration.json",
        "scenario.json",
        "empty-detection-list.json",
        "processing-intermediates.json",
        "empty-processing-intermediates.json",
        "compatibility.json",
    )
    for name in canonical_names:
        value = read_json_artifact(name)
        canonical_reports.append(
            check_artifact(value, _artifact_kind(name, value), name)
        )
    manifest_results = run_manifest()
    failures: list[dict[str, Any]] = [
        report for report in canonical_reports if report["status"] != "passed"
    ]
    for result in manifest_results:
        fixture = result["fixture"]
        if fixture.get("tool") == "matlab":
            continue
        if fixture["expected"] == "accept" and result["status"] != "passed":
            failures.append(result)
        if fixture["expected"] == "reject":
            diagnostics = result.get("report", {}).get("diagnostics", [])
            expected = (fixture["expectedCode"], fixture["expectedPath"])
            if (
                result["status"] != "failed"
                or not diagnostics
                or (diagnostics[0]["code"], diagnostics[0]["path"]) != expected
            ):
                failures.append(result)
    return {
        "status": "passed" if not failures else "failed",
        "canonical": canonical_reports,
        "manifest": manifest_results,
        "failures": failures,
    }


if __name__ == "__main__":
    result = check()
    if result["status"] != "passed":
        print(json.dumps(result, indent=2))
        raise SystemExit(1)
    executed = sum(item["status"] != "skipped" for item in result["manifest"])
    print(f"WP3 conformance passed ({executed} executable manifest rows)")
