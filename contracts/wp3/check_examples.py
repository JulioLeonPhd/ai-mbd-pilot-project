"""Check the WP3 draft JSON examples and cross-document references."""

import hashlib
import json
import math
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent / "examples"
VERSION = re.compile(r"^\d+\.\d+\.\d+(?:-draft\.\d+)?$")


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
    require(config.get("adcBits") == 16, "ADC bit depth must be 16")
    array = config["array"]
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
    require(output.get("detections") == [], "expected zero-result example")
    require(output.get("fixtureScope") == "unit-only", "wrong fixture scope")
    metadata = output["metadata"]
    require(
        metadata["configurationHash"]
        == hashlib.sha256((ROOT / "configuration.json").read_bytes()).hexdigest(),
        "configuration hash disagrees",
    )
    require(
        metadata["testVectorHash"]
        == hashlib.sha256((ROOT / "test-vector.mat").read_bytes()).hexdigest(),
        "MAT hash disagrees",
    )
    require(
        output.get("metadata", {}).get("methodStatus") == "pending-wp7",
        "example must remain non-acceptance",
    )


if __name__ == "__main__":
    check()
    print("WP3 draft JSON examples conform to the checked subset")
