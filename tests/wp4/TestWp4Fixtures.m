classdef TestWp4Fixtures < matlab.unittest.TestCase
%TESTWP4FIXTURES Execute the 54 approved WP4/G2 acceptance rows.

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
        firstPriBoundary = double(evidence.boundaryTicks(1));
        fault = testCase.resetBoundaryStream(streaming, firstPriBoundary, "stage1");
        diagnostic = wp4oracle.checkDdcStreaming(fault);
        testCase.verifyFalse(diagnostic.accepted);
        testCase.verifyEqual(string(diagnostic.code), "NUMERICAL_MISMATCH");
        transitionIndex = find(string({evidence.schedule.records.role}) == "transition", 1);
        transitionEntry = double(evidence.schedule.records(transitionIndex).startTick);
        transitionExit = double(evidence.schedule.records(transitionIndex).endTick);
        fault = testCase.resetBoundaryStream(streaming, transitionEntry, "stage2");
        diagnostic = wp4oracle.checkDdcStreaming(fault);
        testCase.verifyFalse(diagnostic.accepted);
        testCase.verifyEqual(string(diagnostic.code), "NUMERICAL_MISMATCH");
        fault = testCase.resetBoundaryStream(streaming, transitionExit, "stage2");
        diagnostic = wp4oracle.checkDdcStreaming(fault);
        testCase.verifyFalse(diagnostic.accepted);
        testCase.verifyEqual(string(diagnostic.code), "NUMERICAL_MISMATCH");
        fault = testCase.resetBoundaryStream(streaming, firstPriBoundary + 7, "mixerCount");
        diagnostic = wp4oracle.checkDdcStreaming(fault);
        testCase.verifyFalse(diagnostic.accepted);
        testCase.verifyEqual(string(diagnostic.code), "NUMERICAL_MISMATCH");
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
        testCase.verifyEqual(numel(manifest.fixtures), 54);
        testCase.verifyEqual(numel(unique(string({manifest.fixtures.id}))), 54);
        testCase.verifyEqual(numel(unique(string({manifest.fixtures.testMethod}))), 54);
        testCase.verifyTrue(all(contains(string({manifest.fixtures.clause}), "#")));
        testCase.verifyTrue(all(strlength(string({manifest.fixtures.productionEntryPoint})) > 0));
        temporaryReport = checkWp4Fixtures(temporaryManifestPath, ...
            struct("StrictTraceability", true));
        testCase.verifyTrue(temporaryReport.passed);

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
            testCase.verifyEqual(string(artifact.generatorRevision), testRevision);
            testCase.verifyEqual(string(artifact.generatorVersion), "wp4gen-test");
            testCase.verifyEqual(string(artifact.generationParameters.fixtureScope), ...
                "acceptance-evidence");
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
    function mutated = resetBoundaryStream(testCase, streaming, resetTick, resetKind)
        evidence = streaming.boundaryEvidence;
        design = radardemo.ddc.createDesign(struct());
        state = radardemo.ddc.initializeState(design, 1);
        offset = 0;
        while offset < resetTick
            chunkSize = min(8192, resetTick - offset);
            indices = offset + (0:chunkSize - 1).';
            input = testCase.makeBoundaryStimulus(indices, evidence.stimulus);
            [~, state] = radardemo.ddc.processChunk(input, state, design);
            offset = offset + chunkSize;
        end
        faultState = state;
        switch string(resetKind)
            case "stage1"
                faultState.stage1Delay = zeros(size(faultState.stage1Delay));
            case "stage2"
                faultState.stage2Delay = zeros(size(faultState.stage2Delay));
            case "mixerCount"
                faultState.inputSampleCount = uint64(0);
            otherwise
                error("TestWp4Fixtures:UnknownReset", "Unknown DDC reset mutation.");
        end
        indices = resetTick + (0:899).';
        input = testCase.makeBoundaryStimulus(indices, evidence.stimulus);
        [faultOutput, ~] = radardemo.ddc.processChunk(input, faultState, design);
        firstOrdinal = ceil(resetTick / 12);
        outputTicks = 12 * (firstOrdinal + (0:numel(faultOutput) - 1).');
        [found, locations] = ismember(outputTicks, double(evidence.outputTicks(:)));
        if ~any(found)
            error("TestWp4Fixtures:ResetWindowMissing", ...
                "The reset segment does not overlap a recorded output window.");
        end
        mutated = streaming;
        selected = find(found);
        mutated.boundaryEvidence.outputSamples(locations(selected)) = faultOutput(selected);
    end

    function samples = makeBoundaryStimulus(~, sampleIndices, stimulus)
        samples = zeros(numel(sampleIndices), 1);
        for toneIndex = 1:numel(stimulus.frequenciesHz)
            samples = samples + stimulus.amplitudes(toneIndex) .* ...
                cos(2 * pi * stimulus.frequenciesHz(toneIndex) / ...
                stimulus.sampleRateHz .* sampleIndices + stimulus.phasesRad(toneIndex));
        end
    end
end
methods (Static, Access=private)
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
