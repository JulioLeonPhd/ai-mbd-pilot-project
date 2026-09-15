"""Check the WP3 draft JSON examples and cross-document references."""

import json
import math
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent / "examples"
VERSION = re.compile(r"^\d+\.\d+\.\d+(?:-draft\.\d+)?$")
DRAFT_SCHEMA_VERSION = "1.0.0-draft.1"
EXPECTED_DOCUMENT_VERSION = "0.2.0"
SPEED_OF_LIGHT_M_PER_S = 299_792_458
EXPECTED_RF_CARRIER_HZ = 2_997_924_580
EXPECTED_WAVELENGTH_M = 0.1
EXPECTED_ELEMENT_SPACING_RATIO = 0.5
EXPECTED_ELEMENT_SPACING_M = 0.05
FLOAT_TOLERANCE = 1e-15


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def read_example(name: str) -> dict:
    with (ROOT / name).open(encoding="utf-8") as stream:
        value = json.load(
            stream,
            parse_constant=lambda token: (_ for _ in ()).throw(
                ValueError(f"nonfinite JSON number: {token}")
            ),
        )
    require(isinstance(value, dict), f"{name}: root must be an object")
    return value


def finite_number(value: object) -> bool:
    return type(value) in (int, float) and math.isfinite(value)


def envelope(value: dict, name: str) -> None:
    require(value.get("schemaName") == name, f"wrong schemaName: {name}")
    for key in ("schemaVersion", "documentVersion"):
        require(
            isinstance(value.get(key), str) and VERSION.fullmatch(value[key]),
            f"invalid {key}",
        )
    require(
        value["schemaVersion"] == DRAFT_SCHEMA_VERSION,
        f"unsupported draft schemaVersion: {value['schemaVersion']}",
    )
    require(isinstance(value.get("id"), str) and bool(value["id"]), "missing id")


def check() -> None:
    config = read_example("configuration.json")
    scenario = read_example("scenario.json")
    output = read_example("empty-detection-list.json")
    envelope(config, "radar.configuration")
    envelope(scenario, "radar.target-scenario")
    envelope(output, "radar.detection-list")

    for key in ("rfCarrierHz", "ifCenterHz", "adcSampleRateHz"):
        require(finite_number(config.get(key)) and config[key] > 0, f"invalid {key}")
    require(
        config["documentVersion"] == EXPECTED_DOCUMENT_VERSION,
        "configuration documentVersion must be 0.2.0",
    )
    require(
        config["rfCarrierHz"] == EXPECTED_RF_CARRIER_HZ,
        "RF carrier must equal the exact 10 cm design carrier",
    )
    wavelength_m = SPEED_OF_LIGHT_M_PER_S / config["rfCarrierHz"]
    require(
        math.isclose(
            wavelength_m,
            EXPECTED_WAVELENGTH_M,
            rel_tol=0.0,
            abs_tol=FLOAT_TOLERANCE,
        ),
        "derived wavelength must equal 0.1 m",
    )
    require(config.get("adcBits") == 16, "ADC bit depth must be 16")
    array = config["array"]
    require(
        math.isclose(
            array["elementSpacingWavelengths"],
            EXPECTED_ELEMENT_SPACING_RATIO,
            rel_tol=0.0,
            abs_tol=FLOAT_TOLERANCE,
        ),
        "array element spacing must be a half-wavelength",
    )
    element_spacing_m = wavelength_m * array["elementSpacingWavelengths"]
    require(
        math.isclose(
            element_spacing_m,
            EXPECTED_ELEMENT_SPACING_M,
            rel_tol=0.0,
            abs_tol=FLOAT_TOLERANCE,
        ),
        "derived element spacing must equal 0.05 m",
    )
    require(
        array["azimuthElements"] * array["elevationElements"]
        == config.get("channelCount")
        == 64,
        "channel map dimensions disagree",
    )
    ddc = config["ddc"]
    require(ddc["decimationFactors"] == [3, 4], "DDC factors disagree")
    require(
        config["adcSampleRateHz"] / 3 == ddc["complexIntermediateRateHz"],
        "intermediate rate disagrees",
    )
    require(
        ddc["complexIntermediateRateHz"] / 4 == ddc["outputRateHz"],
        "output rate disagrees",
    )
    waveform = config["waveform"]
    require(
        waveform["chirpStopHz"] - waveform["chirpStartHz"]
        == waveform["chirpBandwidthHz"],
        "chirp bandwidth disagrees",
    )
    require(
        config["processing"]["rangeDomainM"] == [6800, 100000], "range domain disagrees"
    )
    require(
        config["processing"]["maxInstrumentedRangeM"] == 100000,
        "instrumented range disagrees",
    )
    expected_pri_ticks = [
        12 * round(config["adcSampleRateHz"] / (12 * prf)) for prf in config["prfsHz"]
    ]
    require(
        config["priSampleCounts"] == expected_pri_ticks,
        "PRI ticks disagree with the /12-aligned candidate rule",
    )

    require(scenario.get("frame") == "radar-centered", "wrong frame")
    require(
        scenario.get("timeEpoch") == output.get("timeEpoch"),
        "global time epoch disagrees",
    )
    require(
        finite_number(scenario.get("scanDurationSec"))
        and scenario["scanDurationSec"] > 0,
        "invalid scan duration",
    )
    ids = set()
    for target in scenario["targets"]:
        require(target["id"] not in ids, "duplicate target id")
        ids.add(target["id"])
        require(finite_number(target["rcsM2"]) and target["rcsM2"] > 0, "invalid RCS")
        for key in ("positionM", "velocityMps"):
            require(
                len(target[key]) == 3 and all(map(finite_number, target[key])),
                f"invalid {key}",
            )

    require(
        output.get("configurationId") == config["id"],
        "detection configurationId disagrees",
    )
    require(
        output["documentVersion"] == EXPECTED_DOCUMENT_VERSION,
        "detection-list documentVersion must be 0.2.0",
    )
    require(output.get("detections") == [], "expected zero-result example")
    require(output.get("fixtureScope") == "unit-only", "wrong fixture scope")
    metadata = output["metadata"]
    require(
        metadata["configurationSchemaVersion"] == config["schemaVersion"]
        and metadata["configurationDocumentVersion"] == config["documentVersion"],
        "configuration version disagrees",
    )
    require(
        output["testVectorId"] == "example-vector-1"
        and metadata["testVectorSchemaVersion"] == "1.0.0-draft.1"
        and metadata["testVectorDocumentVersion"] == EXPECTED_DOCUMENT_VERSION,
        "test-vector provenance disagrees",
    )
    require(
        output.get("metadata", {}).get("methodStatus") == "pending-wp7",
        "example must remain non-acceptance",
    )


if __name__ == "__main__":
    check()
    print("WP3 draft JSON examples conform to the checked subset")
