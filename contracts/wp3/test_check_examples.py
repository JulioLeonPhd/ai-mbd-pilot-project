"""Behavioral tests for the public WP3 JSON conformance checker."""

import copy
import importlib.util
import json
import unittest
from pathlib import Path

MODULE_PATH = Path(__file__).with_name("check_examples.py")
SPEC = importlib.util.spec_from_file_location("wp3_check_examples", MODULE_PATH)
assert SPEC is not None and SPEC.loader is not None
CHECKER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(CHECKER)


class CheckExamplesTests(unittest.TestCase):
    def test_canonical_examples_and_manifest_pass(self) -> None:
        report = CHECKER.check()
        self.assertEqual(report["status"], "passed")
        self.assertEqual(report["failures"], [])

    def test_diagnostics_have_exact_code_and_path(self) -> None:
        configuration = CHECKER.read_json_artifact("configuration.json")
        configuration["rfCarrierHz"] = 2997924581
        report = CHECKER.check_artifact(configuration, "configuration")
        self.assertEqual(report["status"], "failed")
        self.assertEqual(
            (report["diagnostics"][0]["code"], report["diagnostics"][0]["path"]),
            ("VALUE_OUT_OF_RANGE", "rfCarrierHz"),
        )

    def test_missing_and_nonfinite_diagnostics_are_structured(self) -> None:
        scenario = CHECKER.read_json_artifact("scenario.json")
        del scenario["targets"][0]["velocityMps"]
        missing = CHECKER.check_artifact(scenario, "scenario")
        self.assertEqual(
            (missing["diagnostics"][0]["code"], missing["diagnostics"][0]["path"]),
            ("MISSING_FIELD", "targets[0].velocityMps"),
        )

        configuration = CHECKER.read_json_artifact("configuration.json")
        configuration["ifCenterHz"] = float("nan")
        nonfinite = CHECKER.check_artifact(configuration, "configuration")
        self.assertEqual(
            (nonfinite["diagnostics"][0]["code"], nonfinite["diagnostics"][0]["path"]),
            ("NONFINITE", "ifCenterHz"),
        )

    def test_manifest_mutations_do_not_modify_base_fixture(self) -> None:
        base = CHECKER.read_json_artifact("scenario.json")
        mutated = CHECKER.apply_mutation(
            base,
            {"operation": "replace", "path": "targets[0].positionM", "value": [1, 2]},
        )
        self.assertEqual(base["targets"][0]["positionM"], [50000, 0, 0])
        self.assertEqual(mutated["targets"][0]["positionM"], [1, 2])

    def test_manifest_is_versioned_and_names_all_categories(self) -> None:
        manifest = json.loads(Path(CHECKER.MANIFEST_PATH).read_text(encoding="utf-8"))
        self.assertEqual(manifest["manifestVersion"], CHECKER.DRAFT_SCHEMA_VERSION)
        expected_categories = {"accept", "reject", "not-applicable"}
        observed_categories = {row["expected"] for row in manifest["fixtures"]}
        self.assertTrue(expected_categories.issubset(observed_categories))
        for row in manifest["fixtures"]:
            self.assertIn("contractRow", row)
            self.assertIn("baseArtifact", row)
            self.assertIn("mutation", row)

    def test_closed_envelope_reports_missing_and_unknown_fields(self) -> None:
        configuration = CHECKER.read_json_artifact("configuration.json")
        del configuration["createdUtc"]
        missing = CHECKER.check_artifact(configuration, "configuration")
        self.assertEqual(
            (missing["diagnostics"][0]["code"], missing["diagnostics"][0]["path"]),
            ("MISSING_FIELD", "createdUtc"),
        )

        configuration = CHECKER.read_json_artifact("configuration.json")
        configuration["unexpectedField"] = True
        unknown = CHECKER.check_artifact(configuration, "configuration")
        self.assertEqual(
            (unknown["diagnostics"][0]["code"], unknown["diagnostics"][0]["path"]),
            ("VALUE_OUT_OF_RANGE", "unexpectedField"),
        )

    def test_configuration_normative_fields_and_invariants(self) -> None:
        configuration = CHECKER.read_json_artifact("configuration.json")
        del configuration["waveform"]["pulseWidthSec"]
        report = CHECKER.check_artifact(configuration, "configuration")
        self.assertEqual(
            (report["diagnostics"][0]["code"], report["diagnostics"][0]["path"]),
            ("MISSING_FIELD", "waveform.pulseWidthSec"),
        )

        configuration = CHECKER.read_json_artifact("configuration.json")
        configuration["waveform"]["chirpStopHz"] = 4e6
        report = CHECKER.check_artifact(configuration, "configuration")
        self.assertEqual(
            (report["diagnostics"][0]["code"], report["diagnostics"][0]["path"]),
            ("INCONSISTENT_RATE", "waveform.chirpBandwidthHz"),
        )

        configuration = CHECKER.read_json_artifact("configuration.json")
        del configuration["scan"]["azimuthSectorDeg"]
        report = CHECKER.check_artifact(configuration, "configuration")
        self.assertEqual(
            (report["diagnostics"][0]["code"], report["diagnostics"][0]["path"]),
            ("MISSING_FIELD", "scan.azimuthSectorDeg"),
        )

        configuration = CHECKER.read_json_artifact("configuration.json")
        del configuration["processing"]["rangeDomainM"]
        report = CHECKER.check_artifact(configuration, "configuration")
        self.assertEqual(
            (report["diagnostics"][0]["code"], report["diagnostics"][0]["path"]),
            ("MISSING_FIELD", "processing.rangeDomainM"),
        )

    def test_scenario_rejects_zero_range_and_detection_domain(self) -> None:
        scenario = CHECKER.read_json_artifact("scenario.json")
        scenario["targets"][0]["positionM"] = [0, 0, 0]
        report = CHECKER.check_artifact(scenario, "scenario")
        self.assertEqual(
            (report["diagnostics"][0]["code"], report["diagnostics"][0]["path"]),
            ("VALUE_OUT_OF_RANGE", "targets[0].positionM"),
        )

        detection = CHECKER.read_json_artifact("empty-detection-list.json")
        detection["detections"] = [
            {
                "detectionId": "d-1",
                "rangeM": 1000,
                "radialVelocityMps": 20,
                "azimuthDeg": 0,
                "elevationDeg": 0,
                "detectionStatistic": {
                    "name": "unit-test",
                    "value": 0,
                    "units": "normalized",
                },
            }
        ]
        report = CHECKER.check_artifact(detection, "detection-list")
        self.assertEqual(
            (report["diagnostics"][0]["code"], report["diagnostics"][0]["path"]),
            ("VALUE_OUT_OF_RANGE", "detections[0].rangeM"),
        )

    def test_nested_envelopes_require_fields_and_closed_records(self) -> None:
        scenario = CHECKER.read_json_artifact("scenario.json")
        del scenario["frame"]
        report = CHECKER.check_artifact(scenario, "scenario")
        self.assertEqual(
            (report["diagnostics"][0]["code"], report["diagnostics"][0]["path"]),
            ("MISSING_FIELD", "frame"),
        )

        scenario = CHECKER.read_json_artifact("scenario.json")
        scenario["targets"][0]["unexpectedField"] = True
        report = CHECKER.check_artifact(scenario, "scenario")
        self.assertEqual(
            (report["diagnostics"][0]["code"], report["diagnostics"][0]["path"]),
            ("VALUE_OUT_OF_RANGE", "targets[0].unexpectedField"),
        )

        detection = CHECKER.read_json_artifact("empty-detection-list.json")
        del detection["configurationId"]
        report = CHECKER.check_artifact(detection, "detection-list")
        self.assertEqual(
            (report["diagnostics"][0]["code"], report["diagnostics"][0]["path"]),
            ("MISSING_FIELD", "configurationId"),
        )

        detection = CHECKER.read_json_artifact("empty-detection-list.json")
        detection["metadata"]["unexpectedField"] = True
        report = CHECKER.check_artifact(detection, "detection-list")
        self.assertEqual(
            (report["diagnostics"][0]["code"], report["diagnostics"][0]["path"]),
            ("VALUE_OUT_OF_RANGE", "metadata.unexpectedField"),
        )

        compatibility = CHECKER.read_json_artifact("compatibility.json")
        del compatibility["migration"]
        report = CHECKER.check_artifact(compatibility, "compatibility")
        self.assertEqual(
            (report["diagnostics"][0]["code"], report["diagnostics"][0]["path"]),
            ("MISSING_FIELD", "migration"),
        )

    def test_scope_acceptance_and_detection_metadata_semantics(self) -> None:
        processing = CHECKER.read_json_artifact("processing-intermediates.json")
        processing["fixtureScope"] = "invalid-scope"
        report = CHECKER.check_artifact(processing, "processing")
        self.assertEqual(
            (report["diagnostics"][0]["code"], report["diagnostics"][0]["path"]),
            ("VALUE_OUT_OF_RANGE", "fixtureScope"),
        )

        detection = CHECKER.read_json_artifact("empty-detection-list.json")
        detection["fixtureScope"] = "acceptance"
        report = CHECKER.check_artifact(detection, "detection-list")
        self.assertEqual(
            (report["diagnostics"][0]["code"], report["diagnostics"][0]["path"]),
            ("MISSING_FIELD", "metadata.scanMidpointTick"),
        )

        detection["metadata"]["scanMidpointTick"] = 0
        report = CHECKER.check_artifact(detection, "detection-list")
        self.assertEqual(
            (report["diagnostics"][0]["code"], report["diagnostics"][0]["path"]),
            ("METHOD_PENDING", "metadata.methodStatus"),
        )

        detection["metadata"]["methodStatus"] = 1
        report = CHECKER.check_artifact(detection, "detection-list")
        self.assertEqual(
            (report["diagnostics"][0]["code"], report["diagnostics"][0]["path"]),
            ("TYPE_MISMATCH", "metadata.methodStatus"),
        )

    def test_stage_metadata_and_cross_stage_provenance(self) -> None:
        processing = CHECKER.read_json_artifact("processing-intermediates.json")
        del processing["stages"][1]["metadata"]["fixtureSeed"]
        report = CHECKER.check_artifact(processing, "processing")
        self.assertEqual(
            (report["diagnostics"][0]["code"], report["diagnostics"][0]["path"]),
            ("MISSING_FIELD", "stages[1].metadata.fixtureSeed"),
        )

        processing = CHECKER.read_json_artifact("processing-intermediates.json")
        processing["stages"][1]["metadata"]["fixtureSeed"] = 1.5
        report = CHECKER.check_artifact(processing, "processing")
        self.assertEqual(
            (report["diagnostics"][0]["code"], report["diagnostics"][0]["path"]),
            ("TYPE_MISMATCH", "stages[1].metadata.fixtureSeed"),
        )

        processing = CHECKER.read_json_artifact("processing-intermediates.json")
        processing["stages"][1]["metadata"]["steeringConvention"] = "wrong"
        report = CHECKER.check_artifact(processing, "processing")
        self.assertEqual(
            (report["diagnostics"][0]["code"], report["diagnostics"][0]["path"]),
            ("VALUE_OUT_OF_RANGE", "stages[1].metadata.steeringConvention"),
        )

        processing = CHECKER.read_json_artifact("processing-intermediates.json")
        processing["stages"][3]["metadata"]["dopplerBinCentersMps"][0] = float("nan")
        report = CHECKER.check_artifact(processing, "processing")
        self.assertEqual(
            (report["diagnostics"][0]["code"], report["diagnostics"][0]["path"]),
            ("NONFINITE", "stages[3].metadata.dopplerBinCentersMps[0]"),
        )

        processing = CHECKER.read_json_artifact("processing-intermediates.json")
        processing["stages"][3]["configurationId"] = "other-configuration"
        report = CHECKER.check_artifact(processing, "processing")
        self.assertEqual(
            (report["diagnostics"][0]["code"], report["diagnostics"][0]["path"]),
            ("PROVENANCE_MISMATCH", "stages[3].configurationId"),
        )

        processing = CHECKER.read_json_artifact("processing-intermediates.json")
        processing["stages"][9]["shape"] = [7, 1]
        report = CHECKER.check_artifact(processing, "processing")
        self.assertEqual(
            (report["diagnostics"][0]["code"], report["diagnostics"][0]["path"]),
            ("DIMENSION_MISMATCH", "stages[9].shape"),
        )

    def test_processing_enforces_record_fields_and_source_chain(self) -> None:
        processing = CHECKER.read_json_artifact("processing-intermediates.json")
        del processing["stages"][7]["data"][0]["threshold"]
        report = CHECKER.check_artifact(processing, "processing")
        self.assertEqual(
            (report["diagnostics"][0]["code"], report["diagnostics"][0]["path"]),
            ("MISSING_FIELD", "stages[7].data[0].threshold"),
        )

        processing = CHECKER.read_json_artifact("processing-intermediates.json")
        processing["stages"][7]["sourceId"] = "unrelated-source"
        report = CHECKER.check_artifact(processing, "processing")
        self.assertEqual(
            (report["diagnostics"][0]["code"], report["diagnostics"][0]["path"]),
            ("PROVENANCE_MISMATCH", "stages[7].sourceId"),
        )

    def test_processing_cluster_and_candidate_contracts(self) -> None:
        processing = CHECKER.read_json_artifact("processing-intermediates.json")
        self.assertEqual(
            CHECKER.check_artifact(processing, "processing")["status"], "passed"
        )
        processing["stages"][5]["data"][0]["rangeM"] = float("nan")
        report = CHECKER.check_artifact(processing, "processing")
        self.assertEqual(
            (report["diagnostics"][0]["code"], report["diagnostics"][0]["path"]),
            ("NONFINITE", "stages[5].data[0].rangeM"),
        )

        processing = CHECKER.read_json_artifact("processing-intermediates.json")
        processing["stages"][9]["data"]["clusters"] = []
        report = CHECKER.check_artifact(processing, "processing")
        self.assertEqual(
            (report["diagnostics"][0]["code"], report["diagnostics"][0]["path"]),
            ("DIMENSION_MISMATCH", "stages[9].data.clusters"),
        )

        processing = CHECKER.read_json_artifact("processing-intermediates.json")
        processing["stages"][9]["metadata"]["hypothesisShape"] = [7, 1]
        report = CHECKER.check_artifact(processing, "processing")
        self.assertEqual(
            (report["diagnostics"][0]["code"], report["diagnostics"][0]["path"]),
            ("DIMENSION_MISMATCH", "stages[9].data.hypotheses"),
        )

    def test_cluster_supports_two_hypotheses_to_one_cluster(self) -> None:
        processing = CHECKER.read_json_artifact("processing-intermediates.json")
        hypothesis = copy.deepcopy(processing["stages"][9]["data"]["hypotheses"][0])
        hypothesis["hypothesisId"] = 2
        processing["stages"][9]["data"]["hypotheses"].append(hypothesis)
        processing["stages"][9]["metadata"]["hypothesisShape"] = [2, 1]
        processing["stages"][9]["data"]["clusters"][0]["hypothesisIds"] = [1, 2]
        self.assertEqual(
            CHECKER.check_artifact(processing, "processing")["status"], "passed"
        )

    def test_fusion_non_boolean_support_mask_is_structured(self) -> None:
        processing = CHECKER.read_json_artifact("processing-intermediates.json")
        processing["stages"][8]["data"][0]["supportMask"][0] = "yes"
        report = CHECKER.check_artifact(processing, "processing")
        self.assertEqual(
            (report["diagnostics"][0]["code"], report["diagnostics"][0]["path"]),
            ("TYPE_MISMATCH", "stages[8].data[0].supportMask"),
        )

    def test_cluster_hypothesis_ids_reject_unhashable_values(self) -> None:
        processing = CHECKER.read_json_artifact("processing-intermediates.json")
        processing["stages"][9]["data"]["hypotheses"][0]["hypothesisId"] = []
        report = CHECKER.check_artifact(processing, "processing")
        self.assertEqual(
            (report["diagnostics"][0]["code"], report["diagnostics"][0]["path"]),
            ("TYPE_MISMATCH", "stages[9].data.hypotheses[0].hypothesisId"),
        )

        processing = CHECKER.read_json_artifact("processing-intermediates.json")
        processing["stages"][9]["data"]["clusters"][0]["hypothesisIds"] = [[]]
        report = CHECKER.check_artifact(processing, "processing")
        self.assertEqual(
            (report["diagnostics"][0]["code"], report["diagnostics"][0]["path"]),
            ("TYPE_MISMATCH", "stages[9].data.clusters[0].hypothesisIds"),
        )

    def test_processing_records_and_units_use_closed_contracts(self) -> None:
        processing = CHECKER.read_json_artifact("processing-intermediates.json")
        processing["stages"][5]["data"][0]["unexpectedField"] = True
        report = CHECKER.check_artifact(processing, "processing")
        self.assertEqual(
            (report["diagnostics"][0]["code"], report["diagnostics"][0]["path"]),
            ("VALUE_OUT_OF_RANGE", "stages[5].data[0].unexpectedField"),
        )

        processing = CHECKER.read_json_artifact("processing-intermediates.json")
        processing["stages"][0]["units"] = ""
        report = CHECKER.check_artifact(processing, "processing")
        self.assertEqual(
            (report["diagnostics"][0]["code"], report["diagnostics"][0]["path"]),
            ("TYPE_MISMATCH", "stages[0].units"),
        )

        processing = CHECKER.read_json_artifact("processing-intermediates.json")
        processing["stages"][4]["shape"] = [1, 2]
        report = CHECKER.check_artifact(processing, "processing")
        self.assertEqual(
            (report["diagnostics"][0]["code"], report["diagnostics"][0]["path"]),
            ("DIMENSION_MISMATCH", "stages[4].shape"),
        )

        processing = CHECKER.read_json_artifact("processing-intermediates.json")
        processing["stages"][7]["data"][0]["prfIndex"] = "1"
        report = CHECKER.check_artifact(processing, "processing")
        self.assertEqual(
            (report["diagnostics"][0]["code"], report["diagnostics"][0]["path"]),
            ("TYPE_MISMATCH", "stages[7].data[0].prfIndex"),
        )

        processing = CHECKER.read_json_artifact("processing-intermediates.json")
        del processing["stages"][0]["data"]["shape"]
        report = CHECKER.check_artifact(processing, "processing")
        self.assertEqual(
            (report["diagnostics"][0]["code"], report["diagnostics"][0]["path"]),
            ("MISSING_FIELD", "stages[0].data.shape"),
        )

        processing = CHECKER.read_json_artifact("processing-intermediates.json")
        del processing["stages"][9]["metadata"]["clusterShape"]
        report = CHECKER.check_artifact(processing, "processing")
        self.assertEqual(
            (report["diagnostics"][0]["code"], report["diagnostics"][0]["path"]),
            ("MISSING_FIELD", "stages[9].metadata.clusterShape"),
        )

    def test_prf_and_decision_invariants_are_exact(self) -> None:
        processing = CHECKER.read_json_artifact("processing-intermediates.json")
        processing["stages"][5]["data"][0]["prfIndex"] = 6
        report = CHECKER.check_artifact(processing, "processing")
        self.assertEqual(
            (report["diagnostics"][0]["code"], report["diagnostics"][0]["path"]),
            ("VALUE_OUT_OF_RANGE", "stages[5].data[0].prfIndex"),
        )

        processing = CHECKER.read_json_artifact("processing-intermediates.json")
        processing["stages"][7]["data"][0]["prfIndex"] = 0
        report = CHECKER.check_artifact(processing, "processing")
        self.assertEqual(
            (report["diagnostics"][0]["code"], report["diagnostics"][0]["path"]),
            ("VALUE_OUT_OF_RANGE", "stages[7].data[0].prfIndex"),
        )

        processing = CHECKER.read_json_artifact("processing-intermediates.json")
        processing["stages"][7]["data"][0]["decisionState"] = "pass"
        processing["stages"][7]["data"][0]["pass"] = False
        report = CHECKER.check_artifact(processing, "processing")
        self.assertEqual(
            (report["diagnostics"][0]["code"], report["diagnostics"][0]["path"]),
            ("VALUE_OUT_OF_RANGE", "stages[7].data[0].pass"),
        )

        processing = CHECKER.read_json_artifact("processing-intermediates.json")
        processing["stages"][8]["data"][0]["supportMask"][0] = True
        processing["stages"][8]["data"][0]["validityMask"][0] = False
        report = CHECKER.check_artifact(processing, "processing")
        self.assertEqual(
            (report["diagnostics"][0]["code"], report["diagnostics"][0]["path"]),
            ("VALUE_OUT_OF_RANGE", "stages[8].data[0].supportMask"),
        )

        processing = CHECKER.read_json_artifact("processing-intermediates.json")
        processing["stages"][8]["data"][0]["voteCount"] = 1
        report = CHECKER.check_artifact(processing, "processing")
        self.assertEqual(
            (report["diagnostics"][0]["code"], report["diagnostics"][0]["path"]),
            ("VALUE_OUT_OF_RANGE", "stages[8].data[0].voteCount"),
        )

        processing = CHECKER.read_json_artifact("processing-intermediates.json")
        processing["stages"][9]["data"]["clusters"][0]["hypothesisIds"] = [99]
        report = CHECKER.check_artifact(processing, "processing")
        self.assertEqual(
            (report["diagnostics"][0]["code"], report["diagnostics"][0]["path"]),
            (
                "PROVENANCE_MISMATCH",
                "stages[9].data.clusters[0].hypothesisIds",
            ),
        )


if __name__ == "__main__":
    unittest.main()
