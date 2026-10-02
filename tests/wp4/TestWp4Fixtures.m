classdef TestWp4Fixtures < matlab.unittest.TestCase
%TESTWP4FIXTURES Execute the WP4/G2 acceptance rows.

methods (TestClassSetup)
    function setupPathsAndFixtures(testCase)
        repoRoot = fileparts(fileparts(fileparts(mfilename("fullpath"))));
        testCase.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(repoRoot, "src")));
        testCase.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(repoRoot, "contracts", "wp4")));
        TestWp4Fixtures.getManifestPath();
    end
end

methods (Test)
    function testScheduleValid(testCase)
        testCase.verifyTrue(testCase.runCase("Schedule-Valid"));
    end
    function testScheduleTickDiscontinuity(testCase)
        testCase.verifyTrue(testCase.runCase("Schedule-Tick-Discontinuity"));
    end
    function testScheduleRoleGrammar(testCase)
        testCase.verifyTrue(testCase.runCase("Schedule-Role-Grammar"));
        schedulePath = fullfile(fileparts(TestWp4Fixtures.getManifestPath()), "schedule.json");
        schedule = jsondecode(fileread(schedulePath));
        extraPriming = schedule;
        extraPriming.records(2).role = "priming";
        extraDiagnostic = wp4oracle.checkArtifact("schedule", extraPriming);
        testCase.verifyFalse(extraDiagnostic.accepted);
        productionExtra = radardemo.conformance.validateArtifact("schedule", extraPriming);
        testCase.verifyFalse(productionExtra.accepted);
        badTransition = schedule;
        transitionIndex = find(string({badTransition.records.role}) == "transition", 1);
        badTransition.records(transitionIndex).sampleCount = 0;
        badDiagnostic = wp4oracle.checkArtifact("schedule", badTransition);
        testCase.verifyFalse(badDiagnostic.accepted);
        productionBadTransition = radardemo.conformance.validateArtifact("schedule", badTransition);
        testCase.verifyFalse(productionBadTransition.accepted);
    end
    function testScheduleVersionMismatch(testCase)
        testCase.verifyTrue(testCase.runCase("Schedule-Version-Mismatch"));
    end
    function testScheduleDimensionMismatch(testCase)
        testCase.verifyTrue(testCase.runCase("Schedule-Dimension-Mismatch"));
        schedulePath = fullfile(fileparts(TestWp4Fixtures.getManifestPath()), "schedule.json");
        schedule = jsondecode(fileread(schedulePath));
        schedule.usableCounts = schedule.usableCounts(1:4);
        diagnostic = radardemo.conformance.validateArtifact("schedule", schedule);
        testCase.verifyFalse(diagnostic.accepted);
        testCase.verifyEqual(string(diagnostic.code), "DIMENSION_MISMATCH");
        testCase.verifyEqual(string(diagnostic.path), "usableCounts");
    end
    function testScheduleVersionPrecedence(testCase)
        testCase.verifyTrue(testCase.runCase("Schedule-Version-Precedence"));
    end
    function testTimingDelayAndNearRange(testCase)
        testCase.verifyTrue(testCase.runCase("Timing-Delay-And-Near-Range"));
        fixtureRoot = fileparts(TestWp4Fixtures.getManifestPath());
        loaded = load(fullfile(fixtureRoot, "timing-gate.mat"), "-mat");
        timing = loaded.timingGate;
        testCase.verifyEqual(timing.delayTicks, uint64(372));
        testCase.verifyEqual(timing.historySpanTicks, uint64(744));
        testCase.verifyEqual(timing.nominalRawMarginTicks, int64(54));
        testCase.verifyEqual(timing.motionBoundRawMarginTicks, int64(46));
        testCase.verifyEqual(timing.motionBoundAlignedMarginTicks, int64(40));
        testCase.verifyTrue(timing.primingVerified);
        testCase.verifyEqual(numel(timing.primingRecordIndices), 5);
        testCase.verifyEqual(numel(timing.usableRecordEvidence), 142);
        diagnostic = wp4oracle.checkTiming(timing);
        testCase.verifyTrue(diagnostic.accepted);
        badTiming = timing;
        badTiming.motionBoundAlignedMarginTicks = int64(41);
        diagnostic = wp4oracle.checkTiming(badTiming);
        testCase.verifyFalse(diagnostic.accepted);
        badTiming = timing;
        badTiming.delayTicks = uint64(373);
        diagnostic = wp4oracle.checkTiming(badTiming);
        testCase.verifyFalse(diagnostic.accepted);
        badTiming = timing;
        badTiming.primingVerified = false;
        diagnostic = wp4oracle.checkTiming(badTiming);
        testCase.verifyFalse(diagnostic.accepted);
        badTiming = timing;
        badTiming.usableRecordEvidence(1).rawGateTick = ...
            badTiming.usableRecordEvidence(1).rawGateTick + uint64(12);
        diagnostic = wp4oracle.checkTiming(badTiming);
        testCase.verifyFalse(diagnostic.accepted);
        badSchedule = timing.schedule;
        badSchedule.records(1).role = "usable";
        badTiming = timing;
        badTiming.schedule = badSchedule;
        diagnostic = wp4oracle.checkTiming(badTiming);
        testCase.verifyFalse(diagnostic.accepted);
        evaluated = radardemo.timing.evaluateReceiveTiming( ...
            badSchedule, timing.timingDesign, timing.timingSpec);
        testCase.verifyFalse(evaluated.accepted);
        testCase.verifyError(@() radardemo.timing.evaluateReceiveTiming( ...
            timing.schedule, timing.timingDesign, struct("nearRangeMarginTicks", 54)), ...
            "radardemo:timing:ExpectedMarginUnsupported");
        profileNames = ["nominalRangeM", "nominalRangeM", "adcRateHz", ...
            "speedOfLightMps", "radialSpeedBoundMps", ...
            "transmitBlankingTicks", "guardTicks"];
        profileValues = [7000, 6800.1, 150e6 + 1, 299792459, 0, 6001, 751];
        expectedPaths = ["timingSpec.nominalRangeM", "timingSpec.nominalRangeM", ...
            "timingDesign.adcRateHz", "timingSpec.speedOfLightMps", ...
            "timingSpec.radialSpeedBoundMps", "timingSpec.transmitBlankingTicks", ...
            "timingSpec.guardTicks"];
        for index = 1:numel(profileNames)
            profileSpec = timing.timingSpec;
            profileDesign = timing.timingDesign;
            if profileNames(index) == "adcRateHz"
                profileSpec.adcRateHz = profileValues(index);
                profileDesign.adcRateHz = profileValues(index);
            else
                profileSpec.(char(profileNames(index))) = profileValues(index);
            end
            coherent = testCase.makeCoherentTiming(timing, profileSpec, profileDesign);
            testCase.verifyTrue(coherent.accepted);
            if index == 1
                testCase.verifyEqual([coherent.nominalRawMarginTicks, ...
                    coherent.motionBoundRawMarginTicks, ...
                    coherent.motionBoundAlignedMarginTicks], int64([254, 247, 241]));
            elseif index == 2
                testCase.verifyEqual([coherent.nominalRawMarginTicks, ...
                    coherent.motionBoundRawMarginTicks, ...
                    coherent.motionBoundAlignedMarginTicks], int64([54, 46, 40]));
            end
            diagnostic = wp4oracle.checkTiming(coherent);
            testCase.verifyFalse(diagnostic.accepted);
            testCase.verifyEqual(string(diagnostic.code), "VALUE_OUT_OF_RANGE");
            testCase.verifyEqual(string(diagnostic.path), expectedPaths(index));
        end
        marginFields = ["nominalRawMarginTicks", "motionBoundRawMarginTicks", ...
            "motionBoundAlignedMarginTicks", "nearRangeMarginTicks"];
        for index = 1:numel(marginFields)
            fractionalTiming = timing;
            fieldName = char(marginFields(index));
            fractionalTiming.(fieldName) = double(fractionalTiming.(fieldName)) + 0.5;
            diagnostic = wp4oracle.checkTiming(fractionalTiming);
            testCase.verifyFalse(diagnostic.accepted);
            testCase.verifyEqual(string(diagnostic.code), "VALUE_OUT_OF_RANGE");
            testCase.verifyEqual(string(diagnostic.path), marginFields(index));
        end
        nonfiniteTiming = timing;
        nonfiniteTiming.timingSpec.nominalRangeM = NaN;
        diagnostic = wp4oracle.checkTiming(nonfiniteTiming);
        testCase.verifyFalse(diagnostic.accepted);
        testCase.verifyEqual(string(diagnostic.code), "NONFINITE");
        testCase.verifyEqual(string(diagnostic.path), "timingSpec.nominalRangeM");
        targetMargins = [-1, 0, 1];
        for index = 1:numel(targetMargins)
            marginSpec = timing.timingSpec;
            marginSpec.radialSpeedBoundMps = 0;
            marginSpec.nominalRangeM = (6756 + targetMargins(index) + 0.5) * ...
                marginSpec.speedOfLightMps / (2 * marginSpec.adcRateHz);
            boundaryTiming = radardemo.timing.evaluateReceiveTiming( ...
                timing.schedule, timing.timingDesign, marginSpec);
            testCase.verifyEqual(boundaryTiming.motionBoundAlignedMarginTicks, ...
                int64(targetMargins(index)));
            testCase.verifyEqual(boundaryTiming.accepted, targetMargins(index) > 0);
        end
    end
    function testDdcResponse(testCase)
        testCase.verifyTrue(testCase.runCase("Ddc-Response"));
        design = radardemo.ddc.createDesign(struct());
        design.stage1Numerator = zeros(1, 25);
        metrics = radardemo.ddc.measureResponse(design, struct());
        testCase.verifyFalse(metrics.accepted);
        diagnostic = radardemo.conformance.validateArtifact("ddc", design);
        testCase.verifyFalse(diagnostic.accepted);
    end
    function testDdcPerPriResponse(testCase)
        testCase.verifyTrue(testCase.runCase("Ddc-PerPri-Response"));
        fixtureRoot = fileparts(TestWp4Fixtures.getManifestPath());
        loaded = load(fullfile(fixtureRoot, "ddc-response-pri.mat"), "-mat");
        response = loaded.ddcDesign;
        diagnostic = wp4oracle.checkArtifact("ddc-response-pri", response);
        testCase.verifyTrue(diagnostic.accepted);
        testCase.verifyEqual(string(response.responseMetricProfile), "cascade-peak-v1");
        testCase.verifyLessThanOrEqual(response.passbandRippleDb, 0.1 + response.metricToleranceDb);
        testCase.verifyGreaterThanOrEqual(response.digitalAliasRejectionDb, ...
            60 - response.metricToleranceDb);

        stage1Changed = response;
        stage1Changed.stage1Numerator = fir1(24, 25e6 / 75e6, kaiser(25, 2));
        changedMetrics = radardemo.ddc.measureResponse(stage1Changed, struct());
        testCase.verifyFalse(changedMetrics.accepted);
        diagnostic = wp4oracle.checkArtifact("ddc-response-pri", stage1Changed);
        testCase.verifyFalse(diagnostic.accepted);
        testCase.verifyEqual(string(diagnostic.code), "DDC_COEFFICIENT_MISMATCH");
        testCase.verifyEqual(string(diagnostic.path), "stage1Numerator");

        nonfinite = response;
        nonfinite.digitalAliasRejectionDb = NaN;
        diagnostic = wp4oracle.checkArtifact("ddc-response-pri", nonfinite);
        testCase.verifyFalse(diagnostic.accepted);
        testCase.verifyEqual(string(diagnostic.code), "NONFINITE");
        badPrincipal = response;
        badPrincipal.principalCascadeResponse(1) = complex(NaN, 0);
        diagnostic = wp4oracle.checkArtifact("ddc-response-pri", badPrincipal);
        testCase.verifyFalse(diagnostic.accepted);
        testCase.verifyEqual(string(diagnostic.code), "NONFINITE");
        badBranch = response;
        badBranch.stage2AliasBranches(1) = complex(0, Inf);
        diagnostic = wp4oracle.checkArtifact("ddc-response-pri", badBranch);
        testCase.verifyFalse(diagnostic.accepted);
        testCase.verifyEqual(string(diagnostic.code), "NONFINITE");
        badTolerance = response;
        badTolerance.metricToleranceDb = NaN;
        diagnostic = wp4oracle.checkArtifact("ddc-response-pri", badTolerance);
        testCase.verifyFalse(diagnostic.accepted);
        testCase.verifyEqual(string(diagnostic.code), "NONFINITE");
        badPassband = response;
        badPassband.passbandHz(1) = NaN;
        diagnostic = wp4oracle.checkArtifact("ddc-response-pri", badPassband);
        testCase.verifyFalse(diagnostic.accepted);
        testCase.verifyEqual(string(diagnostic.code), "NONFINITE");
    end
    function testDdcPerPriProcessing(testCase)
        testCase.verifyTrue(testCase.runCase("Ddc-PerPri-Processing"));
        fixtureRoot = fileparts(TestWp4Fixtures.getManifestPath());
        loaded = load(fullfile(fixtureRoot, "ddc-pri.mat"), "-mat");
        evidence = loaded.ddcPri;
        design = radardemo.ddc.createDesign(struct());
        probe = TestWp4Fixtures.probePerPriProcessing(evidence, design);
        testCase.verifyTrue(probe.orderInvariant);
        testCase.verifyLessThanOrEqual(probe.maximumNormalizedError, ...
            evidence.normalizedTolerance);
        testCase.verifyTrue(probe.zero64IsExact);
        testCase.verifyTrue(probe.channelIsolationIsExact);
        testCase.verifyEqual(string(probe.badMetadataCode), "VALUE_OUT_OF_RANGE");
        testCase.verifyEqual(string(probe.badOutputCode), "NUMERICAL_MISMATCH");
        testCase.verifyEqual(string(probe.badCoordinateCode), "VALUE_OUT_OF_RANGE");
        testCase.verifyEqual(probe.tinyOutputCodes, ...
            repmat("NUMERICAL_MISMATCH", 1, 6));
    end
    function testDdcStreamingState(testCase)
        testCase.verifyTrue(testCase.runCase("Ddc-Streaming-State"));
        fixtureRoot = fileparts(TestWp4Fixtures.getManifestPath());
        loaded = load(fullfile(fixtureRoot, "ddc-streaming.mat"), "-mat");
        streaming = loaded.ddcStreaming;
        evidence = streaming.boundaryEvidence;
        testCase.verifyEqual(numel(evidence.boundaryTicks), 150);
        testCase.verifyLessThanOrEqual(max(evidence.chunkLengths), 8192);
        importantTicks = [88236, 2029428, 2136300, 2215248, 8553228, 8608788];
        cumulativeInputs = cumsum(double(evidence.chunkLengths(:)));
        for index = 1:numel(importantTicks)
            row = find(cumulativeInputs == importantTicks(index), 1);
            testCase.verifyNotEmpty(row);
            checkpoint = evidence.checkpoints(row, :);
            testCase.verifyEqual(checkpoint(2), mod(importantTicks(index), 3));
            testCase.verifyEqual(checkpoint(3), mod(ceil(importantTicks(index) / 3), 4));
            testCase.verifyEqual(checkpoint(4), ceil(importantTicks(index) / 12));
        end
        testCase.verifyEqual(string(streaming.schemaName), "radar.wp4.ddc-streaming");
        testCase.verifyEqual(string(streaming.generatorRevision), ...
            "0fe89d45fa20a9f0f68ae6908855dbc61835b083");
        diagnostic = wp4oracle.checkDdcStreaming(streaming);
        testCase.verifyTrue(diagnostic.accepted);
    end
    function testDdcZeroInput(testCase)
        testCase.verifyTrue(testCase.runCase("Ddc-Zero-Input"));
    end
    function testDdcRippleDiagnostic(testCase)
        testCase.verifyTrue(testCase.runCase("Ddc-Ripple-Diagnostic"));
    end
    function testDdcAliasDiagnostic(testCase)
        testCase.verifyTrue(testCase.runCase("Ddc-Alias-Diagnostic"));
    end
    function testDdcStopbandEdgeDiagnostic(testCase)
        testCase.verifyTrue(testCase.runCase("Ddc-Stopband-Edge-Diagnostic"));
    end
    function testDdcCoefficientDimension(testCase)
        testCase.verifyTrue(testCase.runCase("Ddc-Coefficient-Dimension"));
    end
    function testDdcSemanticPrecedence(testCase)
        testCase.verifyTrue(testCase.runCase("Ddc-Semantic-Precedence"));
    end
    function testDdcNonfiniteCoefficient(testCase)
        testCase.verifyTrue(testCase.runCase("Ddc-Nonfinite-Coefficient"));
    end
    function testBeamBoresight(testCase)
        testCase.verifyTrue(testCase.runCase("Beam-Boresight"));
        loaded = load(fullfile(fileparts(TestWp4Fixtures.getManifestPath()), ...
            "beam-boresight.mat"), "-mat");
        diagnostic = radardemo.conformance.validateArtifact("beam", loaded.beamFixture);
        testCase.verifyTrue(diagnostic.accepted);
    end
    function testBeamPositiveOffBoresight(testCase)
        testCase.verifyTrue(testCase.runCase("Beam-Positive-Off-Boresight"));
    end
    function testBeamNegativeOffBoresight(testCase)
        testCase.verifyTrue(testCase.runCase("Beam-Negative-Off-Boresight"));
    end
    function testBeamSignInversion(testCase)
        testCase.verifyTrue(testCase.runCase("Beam-Sign-Inversion"));
    end
    function testBeamInputDimension(testCase)
        testCase.verifyTrue(testCase.runCase("Beam-Input-Dimension"));
    end
    function testBeamZeroInput(testCase)
        testCase.verifyTrue(testCase.runCase("Beam-Zero-Input"));
    end
    function testBeamVersionPrecedence(testCase)
        testCase.verifyTrue(testCase.runCase("Beam-Version-Precedence"));
    end
    function testFusionPass(testCase)
        testCase.verifyTrue(testCase.runCase("Fusion-Pass"));
        fusionCase = testCase.getFusionCase("pass");
        testCase.verifyEqual(logical(fusionCase.validityMask(:).'), true(1, 5));
        testCase.verifyEqual(logical(fusionCase.supportMask(:).'), [true, true, true, false, false]);
        testCase.verifyEqual(logical(fusionCase.passMask(:).'), [true, true, true, false, false]);
        testCase.verifyEqual(fusionCase.voteCount, 3);
        testCase.verifyEqual(string(fusionCase.outcome), "pass");
    end
    function testFusionFail(testCase)
        testCase.verifyTrue(testCase.runCase("Fusion-Fail"));
        fusionCase = testCase.getFusionCase("fail");
        testCase.verifyEqual(logical(fusionCase.validityMask(:).'), true(1, 5));
        testCase.verifyEqual(logical(fusionCase.supportMask(:).'), true(1, 5));
        testCase.verifyEqual(logical(fusionCase.passMask(:).'), [true, false, false, false, false]);
        testCase.verifyEqual(fusionCase.voteCount, 1);
        testCase.verifyEqual(string(fusionCase.outcome), "fail");
    end
    function testFusionInvalidOutcome(testCase)
        testCase.verifyTrue(testCase.runCase("Fusion-Invalid-Outcome"));
        fusionCase = testCase.getFusionCase("invalid");
        expectedMask = [true, false, false, false, false];
        testCase.verifyEqual(logical(fusionCase.validityMask(:).'), expectedMask);
        testCase.verifyEqual(logical(fusionCase.supportMask(:).'), expectedMask);
        testCase.verifyEqual(logical(fusionCase.passMask(:).'), expectedMask);
        testCase.verifyEqual(fusionCase.voteCount, 1);
        testCase.verifyEqual(string(fusionCase.outcome), "invalid");
    end
    function testFusionZeroHypotheses(testCase)
        testCase.verifyTrue(testCase.runCase("Fusion-Zero-Hypotheses"));
    end
    function testFusionSupportSubset(testCase)
        manifestPath = TestWp4Fixtures.getManifestPath();
        manifest = jsondecode(fileread(manifestPath));
        row = manifest.fixtures(string({manifest.fixtures.id}) == "FUS-005");
        testCase.verifyEqual(numel(row.mutation), 2);
        testCase.verifyEqual(string({row.mutation.path}), ["validityMask", "supportMask"]);
        testCase.verifyEqual(logical(row.mutation(1).value(:).'), [true, true, true, true, false]);
        testCase.verifyEqual(logical(row.mutation(2).value(:).'), true(1, 5));
        report = checkWp4Fixtures(manifestPath, struct("CaseId", "FUS-005"));
        testCase.verifyTrue(report.passed);
        testCase.verifyFalse(report.cases.accepted);
        testCase.verifyEqual(string(report.cases.actualCode), "VALUE_OUT_OF_RANGE");
        testCase.verifyEqual(string(report.cases.actualPath), "supportMask");
    end
    function testFusionMaskDimension(testCase)
        testCase.verifyTrue(testCase.runCase("Fusion-Mask-Dimension"));
    end
    function testFusionThreshold(testCase)
        testCase.verifyTrue(testCase.runCase("Fusion-Threshold"));
    end
    function testFusionDiagnosticPrecedence(testCase)
        testCase.verifyTrue(testCase.runCase("Fusion-Diagnostic-Precedence"));
    end
    function testClusterSingleAggregate(testCase)
        testCase.verifyTrue(testCase.runCase("Cluster-Single-Aggregate"));
    end
    function testClusterMergeAggregate(testCase)
        testCase.verifyTrue(testCase.runCase("Cluster-Merge-Aggregate"));
    end
    function testClusterInputOrder(testCase)
        testCase.verifyTrue(testCase.runCase("Cluster-Input-Order"));
    end
    function testClusterNoWrap(testCase)
        testCase.verifyTrue(testCase.runCase("Cluster-No-Wrap"));
    end
    function testClusterNoBridge(testCase)
        testCase.verifyTrue(testCase.runCase("Cluster-No-Bridge"));
    end
    function testClusterSameLook(testCase)
        testCase.verifyTrue(testCase.runCase("Cluster-Same-Look"));
    end
    function testClusterDuplicateCell(testCase)
        testCase.verifyTrue(testCase.runCase("Cluster-Duplicate-Cell"));
    end
    function testClusterZeroResult(testCase)
        testCase.verifyTrue(testCase.runCase("Cluster-Zero-Result"));
    end
    function testClusterAllIneligible(testCase)
        testCase.verifyTrue(testCase.runCase("Cluster-All-Ineligible"));
    end
    function testClusterStatisticTie(testCase)
        testCase.verifyTrue(testCase.runCase("Cluster-Statistic-Tie"));
    end
    function testClusterMaskDimension(testCase)
        testCase.verifyTrue(testCase.runCase("Cluster-Mask-Dimension"));
    end
    function testClusterAggregateMismatch(testCase)
        testCase.verifyTrue(testCase.runCase("Cluster-Aggregate-Mismatch"));
    end
    function testClusterUnknownMember(testCase)
        testCase.verifyTrue(testCase.runCase("Cluster-Unknown-Member"));
    end
    function testClusterDiagnosticPrecedence(testCase)
        testCase.verifyTrue(testCase.runCase("Cluster-Diagnostic-Precedence"));
    end
    function testDraft1DirectRejection(testCase)
        draft = struct("schemaVersion", "1.0.0-draft.1");
        diagnostic = radardemo.conformance.validateArtifact("schedule", draft);
        testCase.verifyFalse(diagnostic.accepted);
        testCase.verifyEqual(string(diagnostic.code), "VERSION_MISMATCH");
    end

    function testDraft1ScheduleAdapter(testCase)
        draft = radardemo.schedule.createReceiveSchedule(struct());
        draft.schemaVersion = "1.0.0-draft.1";
        [migrated, diagnostic] = adaptWp4Draft1("schedule", draft, ...
            struct("priSampleCounts", draft.priSampleCounts, "transitionGapTicks", 106872));
        testCase.verifyTrue(diagnostic.accepted);
        testCase.verifyEqual(string(migrated.schemaVersion), "1.0.0-draft.2");
    end

    function testDraft1DdcAdapter(testCase)
        design = radardemo.ddc.createDesign(struct());
        draft = struct("schemaVersion", "1.0.0-draft.1");
        context = struct("design", design);
        [migrated, diagnostic] = adaptWp4Draft1("ddc", draft, context);
        testCase.verifyTrue(diagnostic.accepted);
        testCase.verifyEqual(numel(migrated.stage2Numerator), 241);
        testCase.verifyEqual(string(migrated.responseMetricProfile), "cascade-peak-v1");
    end

    function testDraft1FusionAdapter(testCase)
        draft = struct("schemaVersion", "1.0.0-draft.1", ...
            "validityMask", true(1, 5), "supportMask", true(1, 5), ...
            "passMask", [true, true, true, false, false]);
        [migrated, diagnostic] = adaptWp4Draft1("fusion", draft, struct());
        testCase.verifyTrue(diagnostic.accepted);
        testCase.verifyEqual(string(migrated.outcome), "pass");
        testCase.verifyEqual(migrated.migrationSeed, 401061);
    end

    function testDraft1ClusterAdapter(testCase)
        draft = struct("schemaVersion", "1.0.0-draft.1", "hypotheses", ...
            struct("hypothesisId", "h1", "rangeM", 1, "radialVelocityMps", 1, ...
            "statistic", 1, "sourceCellIds", {{ "p1:c1" }}));
        context = struct("commandedLooks", struct("hypothesisId", "h1", ...
            "azimuthLookIndex", 1, "elevationLookIndex", 1, "clusterCell", [1, 1], ...
            "clusterEligible", true, "validityMask", true(1, 5), ...
            "supportMask", true(1, 5), "passMask", true(1, 5)));
        [migrated, diagnostic] = adaptWp4Draft1("clustering", draft, context);
        testCase.verifyTrue(diagnostic.accepted);
        testCase.verifyTrue(migrated.hypotheses.clusterEligible);
        testCase.verifyEqual(migrated.hypotheses.clusterCell, [1, 1]);
    end

    function testDraft1MissingLookContext(testCase)
        draft = struct("schemaVersion", "1.0.0-draft.1", "hypotheses", struct([]));
        [~, diagnostic] = adaptWp4Draft1("clustering", draft, struct());
        testCase.verifyFalse(diagnostic.accepted);
        testCase.verifyEqual(string(diagnostic.code), "MISSING_FIELD");
        testCase.verifyEqual(string(diagnostic.path), "context.commandedLooks");
    end

    function testDraft1AmbiguousLookContext(testCase)
        draft = struct("schemaVersion", "1.0.0-draft.1", "hypotheses", ...
            struct("hypothesisId", "h1", "rangeM", 1, "radialVelocityMps", 1, ...
            "statistic", 1, "sourceCellIds", {{ "p1:c1" }}));
        context = struct("commandedLooks", struct("hypothesisId", "other", ...
            "azimuthLookIndex", 1, "elevationLookIndex", 1, "clusterCell", [1, 1], ...
            "clusterEligible", true));
        [~, diagnostic] = adaptWp4Draft1("clustering", draft, context);
        testCase.verifyFalse(diagnostic.accepted);
        testCase.verifyEqual(string(diagnostic.code), "PROVENANCE_MISMATCH");
    end

    function testManifestTraceability(testCase)
        temporaryManifestPath = TestWp4Fixtures.getManifestPath();
        manifest = jsondecode(fileread(temporaryManifestPath));
        testCase.verifyEqual(numel(manifest.fixtures), 56);
        testCase.verifyEqual(numel(unique(string({manifest.fixtures.id}))), 56);
        testCase.verifyEqual(numel(unique(string({manifest.fixtures.testMethod}))), 56);
        testCase.verifyTrue(all(contains(string({manifest.fixtures.clause}), "#")));
        testCase.verifyTrue(all(strlength(string({manifest.fixtures.productionEntryPoint})) > 0));
        temporaryReport = checkWp4Fixtures(temporaryManifestPath, ...
            struct("StrictTraceability", true));
        testCase.verifyTrue(temporaryReport.passed);
        testCase.verifyTrue(temporaryReport.includesWorkingTreeEvidence);
        testCase.verifyTrue(ismember("temporary-unit-evidence", temporaryReport.evidenceScopes));
        testCase.verifyTrue(ismember("acceptance-evidence", temporaryReport.evidenceScopes));

        invalidRoot = tempname;
        mkdir(invalidRoot);
        testCase.verifyError(@() generateWp4Fixtures(invalidRoot, struct( ...
            "FixtureScope", "acceptance-evidence", "GeneratorRevision", "working-tree")), ...
            "wp4:ImmutableRevision");

        acceptanceRoot = tempname;
        mkdir(acceptanceRoot);
        testRevision = "0123456789abcdef0123456789abcdef01234567";
        acceptanceReport = generateWp4Fixtures(acceptanceRoot, struct( ...
            "FixtureScope", "acceptance-evidence", "GeneratorRevision", testRevision, ...
            "GeneratorVersion", "wp4gen-test", "CreatedUtc", "2026-09-21T00:00:00Z"));
        acceptanceManifest = jsondecode(fileread(acceptanceReport.manifestPath));
        testCase.verifyEqual(string(acceptanceManifest.status), "acceptance-evidence");
        testCase.verifyEqual(string(acceptanceManifest.fixtureScope), "acceptance-evidence");
        testCase.verifyEqual(string(acceptanceManifest.generatorRevision), testRevision);
        acceptanceChecked = checkWp4Fixtures(acceptanceReport.manifestPath, ...
            struct("StrictTraceability", true));
        testCase.verifyTrue(acceptanceChecked.passed);
        testCase.verifyFalse(acceptanceChecked.includesWorkingTreeEvidence);
        for artifactIndex = 1:numel(acceptanceReport.artifacts)
            artifactName = string(acceptanceReport.artifacts{artifactIndex});
            artifactPath = fullfile(acceptanceRoot, artifactName);
            if endsWith(artifactName, ".json")
                artifact = jsondecode(fileread(artifactPath));
            else
                loaded = load(artifactPath, "-mat");
                variableNames = fieldnames(loaded);
                artifact = loaded.(variableNames{1});
            end
            provenanceRows = acceptanceManifest.artifactProvenance( ...
                string({acceptanceManifest.artifactProvenance.artifact}) == artifactName);
            if isempty(provenanceRows)
                expectedRevision = testRevision;
                expectedVersion = "wp4gen-test";
                expectedScope = "acceptance-evidence";
                expectedCreatedUtc = "2026-09-21T00:00:00Z";
            else
                expectedRevision = string(provenanceRows.generatorRevision);
                expectedVersion = string(provenanceRows.generatorVersion);
                expectedScope = string(provenanceRows.evidenceScope);
                expectedCreatedUtc = string(provenanceRows.createdUtc);
            end
            testCase.verifyEqual(string(artifact.generatorRevision), expectedRevision);
            testCase.verifyEqual(string(artifact.generatorVersion), expectedVersion);
            testCase.verifyEqual(string(artifact.generationParameters.fixtureScope), ...
                expectedScope);
            testCase.verifyEqual(string(artifact.createdUtc), expectedCreatedUtc);
            matchingRows = acceptanceManifest.fixtures( ...
                string({acceptanceManifest.fixtures.artifact}) == artifactName);
            testCase.verifyNotEmpty(matchingRows);
            testCase.verifyEqual(artifact.generatorSeed, matchingRows(1).provenanceSeed);
        end
    end

    function testGeneratorOracleSeparation(testCase)
        repoRoot = fileparts(fileparts(fileparts(mfilename("fullpath"))));
        sourceFiles = dir(fullfile(repoRoot, "src", "+radardemo", "**", "*.m"));
        generatorFiles = dir(fullfile(repoRoot, "contracts", "wp4", "+wp4gen", "**", "*.m"));
        oracleFiles = dir(fullfile(repoRoot, "contracts", "wp4", "+wp4oracle", "**", "*.m"));
        sourceText = testCase.readFiles(sourceFiles);
        generatorText = testCase.readFiles(generatorFiles);
        oracleText = testCase.readFiles(oracleFiles);
        testCase.verifyTrue(all(~contains(sourceText, "contracts/wp4")));
        testCase.verifyTrue(all(~contains(generatorText, "wp4oracle")));
        testCase.verifyTrue(all(~contains(oracleText, "radardemo")));
        testCase.verifyTrue(all(~contains(oracleText, "wp4gen")));
        testCase.verifyTrue(any(contains(generatorText, "radardemo.ddc")));
    end
end

methods (Access=private)
    function text = readFiles(~, files)
        text = strings(numel(files), 1);
        for index = 1:numel(files)
            text(index) = lower(string(fileread(fullfile(files(index).folder, files(index).name))));
        end
    end

    function passed = runCase(testCase, caseId)
        manifest = jsondecode(fileread(TestWp4Fixtures.getManifestPath()));
        names = upper(string({manifest.fixtures.testMethod}));
        names = erase(names, "TEST");
        names = erase(names, "-");
        normalizedCase = erase(upper(string(caseId)), "-");
        match = names == normalizedCase;
        testCase.verifyTrue(any(match));
        row = manifest.fixtures(find(match, 1));
        report = checkWp4Fixtures(TestWp4Fixtures.getManifestPath(), struct("CaseId", row.id));
        passed = report.caseCount == 1 && report.passed;
    end

    function coherent = makeCoherentTiming(~, source, spec, design)
        proof = radardemo.timing.evaluateReceiveTiming(source.schedule, design, spec);
        coherent = source;
        proofFields = fieldnames(proof);
        for fieldIndex = 1:numel(proofFields)
            fieldName = proofFields{fieldIndex};
            coherent.(fieldName) = proof.(fieldName);
        end
        coherent.timingSpec = spec;
        coherent.timingDesign = design;
    end

    function fusionCase = getFusionCase(~, caseId)
        fusionPath = fullfile(fileparts(TestWp4Fixtures.getManifestPath()), "fusion-cases.json");
        artifact = jsondecode(fileread(fusionPath));
        matches = string({artifact.cases.caseId}) == string(caseId);
        fusionCase = artifact.cases(find(matches, 1));
    end
end
methods (Static, Access=private)
    function result = probePerPriProcessing(evidence, design)
        canonicalOutput = cell(5, 1);
        canonicalMetadata = cell(5, 1);
        shuffledOrder = [4, 1, 5, 2, 3, 4, 1];
        callOrders = {1:5, 5:-1:1, shuffledOrder, shuffledOrder};
        maximumNormalizedError = 0;
        orderInvariant = true;
        for orderIndex = 1:numel(callOrders)
            order = callOrders{orderIndex};
            for caseIndex = order
                item = evidence.cases(caseIndex);
                [output, metadata] = radardemo.ddc.processFrame(item.input, design);
                referenceAmplitude = max(abs(item.input(:)));
                if referenceAmplitude == 0
                    referenceAmplitude = 1;
                end
                normalizedError = max(abs(output(:) - item.expectedOutput(:))) / ...
                    referenceAmplitude;
                maximumNormalizedError = max(maximumNormalizedError, normalizedError);
                orderInvariant = orderInvariant && isequal(size(output), size(item.expectedOutput)) && ...
                    isequal(metadata, item.metadata);
                if orderIndex == 1
                    canonicalOutput{caseIndex} = output;
                    canonicalMetadata{caseIndex} = metadata;
                else
                    orderInvariant = orderInvariant && ...
                        isequal(output, canonicalOutput{caseIndex}) && ...
                        isequal(metadata, canonicalMetadata{caseIndex});
                end
            end
        end

        zero64 = evidence.cases(6);
        [zeroOutput, zeroMetadata] = radardemo.ddc.processFrame(zero64.input, design);
        expectedZero = complex(zeros(size(zeroOutput)));
        zero64IsExact = isequal(size(zeroOutput), [size(zero64.input, 1) / 12, 64]) && ...
            isequal(zeroOutput, expectedZero) && isequal(zeroMetadata, zero64.metadata);
        isolation = evidence.cases(7);
        isolationOutput = radardemo.ddc.processFrame(isolation.input, design);
        inactiveChannels = setdiff(1:64, isolation.targetChannel);
        expectedInactive = complex(zeros(size(isolationOutput, 1), numel(inactiveChannels)));
        channelIsolationIsExact = isequal(isolationOutput(:, inactiveChannels), expectedInactive);

        badMetadata = evidence;
        badMetadata.cases(2).metadata.outputSampleCount = ...
            badMetadata.cases(2).metadata.outputSampleCount + 1;
        metadataDiagnostic = wp4oracle.checkDdcPri(badMetadata);
        badOutput = evidence;
        badOutput.cases(4).expectedOutput(100, 1) = ...
            badOutput.cases(4).expectedOutput(100, 1) + 0.01;
        outputDiagnostic = wp4oracle.checkDdcPri(badOutput);
        badCoordinates = evidence;
        badCoordinates.cases(2).coordinateMap.compensatedOutputStartTick = ...
            badCoordinates.cases(2).coordinateMap.compensatedOutputStartTick + 1;
        coordinateDiagnostic = wp4oracle.checkDdcPri(badCoordinates);
        tinyOutputCodes = TestWp4Fixtures.checkTinyOutputCorruptions(evidence);
        result = struct("orderInvariant", orderInvariant, ...
            "maximumNormalizedError", maximumNormalizedError, ...
            "zero64IsExact", zero64IsExact, ...
            "channelIsolationIsExact", channelIsolationIsExact, ...
            "badMetadataCode", metadataDiagnostic.code, ...
            "badOutputCode", outputDiagnostic.code, ...
            "badCoordinateCode", coordinateDiagnostic.code, ...
            "tinyOutputCodes", tinyOutputCodes);
    end

    function codes = checkTinyOutputCorruptions(evidence)
        mutated = evidence;
        mutated.cases(1).expectedOutput(1, 1) = 1e-12;
        oneChannelReal = wp4oracle.checkDdcPri(mutated);
        mutated = evidence;
        mutated.cases(1).expectedOutput(1, 1) = complex(0, 1e-12);
        oneChannelImaginary = wp4oracle.checkDdcPri(mutated);
        mutated = evidence;
        mutated.cases(6).expectedOutput(1, 1) = 1e-12;
        sixtyFourChannelReal = wp4oracle.checkDdcPri(mutated);
        mutated = evidence;
        mutated.cases(6).expectedOutput(1, 1) = complex(0, 1e-12);
        sixtyFourChannelImaginary = wp4oracle.checkDdcPri(mutated);
        mutated = evidence;
        mutated.cases(7).expectedOutput(1, 1) = 1e-12;
        inactiveChannelReal = wp4oracle.checkDdcPri(mutated);
        mutated = evidence;
        mutated.cases(7).expectedOutput(1, 1) = complex(0, 1e-12);
        inactiveChannelImaginary = wp4oracle.checkDdcPri(mutated);
        codes = [string(oneChannelReal.code), string(oneChannelImaginary.code), ...
            string(sixtyFourChannelReal.code), string(sixtyFourChannelImaginary.code), ...
            string(inactiveChannelReal.code), string(inactiveChannelImaginary.code)];
    end

    function manifestPath = getManifestPath()
        persistent savedManifestPath
        if isempty(savedManifestPath) || ~isfile(savedManifestPath)
            fixtureRoot = tempname;
            mkdir(fixtureRoot);
            generated = generateWp4Fixtures(fixtureRoot, struct("GeneratorRevision", "temporary"));
            savedManifestPath = string(generated.manifestPath);
        end
        manifestPath = savedManifestPath;
    end
end
end
