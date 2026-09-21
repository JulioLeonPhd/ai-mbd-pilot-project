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
    end
    function testFusionFail(testCase)
        testCase.verifyTrue(testCase.runCase("Fusion-Fail"));
    end
    function testFusionInvalidOutcome(testCase)
        testCase.verifyTrue(testCase.runCase("Fusion-Invalid-Outcome"));
    end
    function testFusionZeroHypotheses(testCase)
        testCase.verifyTrue(testCase.runCase("Fusion-Zero-Hypotheses"));
    end
    function testFusionSupportSubset(testCase)
        testCase.verifyTrue(testCase.runCase("Fusion-Support-Subset"));
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
