function report = checkWp4Fixtures(manifestPath, options)
%CHECKWP4FIXTURES Run the independent WP4/G2 checker against a manifest.

arguments
    manifestPath (1, 1) string
    options struct = struct()
end

defaults = struct("CaseId", "", "FixtureRoot", "", "StrictTraceability", false);
options = mergeOptions(defaults, options);
manifest = jsondecode(fileread(manifestPath));
root = string(options.FixtureRoot);
if strlength(root) == 0
    root = string(fileparts(manifestPath));
end
rows = manifest.fixtures;
if strlength(string(options.CaseId)) > 0
    rows = rows(strcmp(string({rows.id}), string(options.CaseId)));
end

caseTemplate = struct("id", "", "testMethod", "", "accepted", false, ...
    "expected", "", "actualCode", "", "actualPath", "", "passed", false, ...
    "message", "");
results = repmat(caseTemplate, numel(rows), 1);
for index = 1:numel(rows)
    row = rows(index);
    results(index).id = char(row.id);
    results(index).testMethod = char(row.testMethod);
    results(index).expected = char(row.expected);
    try
        if row.domain == "migration"
            diagnostic = checkMigrationCase(string(row.id));
        elseif row.domain == "meta"
            diagnostic = checkMetaCase(string(row.id), manifest, root);
        elseif isempty(row.artifact)
            diagnostic = struct("accepted", false, "code", "MISSING_FIELD", ...
                "path", "artifact", "message", "Artifact selector is required.", "output", struct());
        else
            artifactPath = fullfile(root, string(row.artifact));
            if ~isfile(artifactPath)
                diagnostic = struct("accepted", false, "code", "MISSING_FIELD", ...
                    "path", "artifact", "message", "Artifact not found.", "output", struct());
            else
                data = loadArtifact(artifactPath);
                data = selectFusionCase(data, string(row.domain));
                if isfield(row, "mutation") && isstruct(row.mutation) && ~isempty(row.mutation)
                    data = applyMutations(data, row.mutation);
                end
                diagnostic = wp4oracle.checkArtifact(string(row.domain), data);
            end
        end
    catch exception
        diagnostic = struct("accepted", false, "code", "INTERNAL_ERROR", ...
            "path", "", "message", string(exception.message), "output", struct());
    end
    results(index).accepted = diagnostic.accepted;
    results(index).actualCode = char(diagnostic.code);
    results(index).actualPath = char(diagnostic.path);
    results(index).message = char(diagnostic.message);
    results(index).passed = matchesExpected(row, diagnostic);
end

if options.StrictTraceability
    for index = 1:numel(rows)
        if ~contains(string(rows(index).clause), "#")
            results(index).passed = false;
            results(index).message = "Traceability clause is not a path#anchor selector.";
        end
    end
end
report = struct();
report.manifestPath = char(manifestPath);
report.cases = results;
report.caseCount = numel(results);
report.passedCount = sum([results.passed]);
report.failedCount = report.caseCount - report.passedCount;
report.passed = report.failedCount == 0;
report.tolerances = struct("ddcDb", 1e-9, "firSymmetry", 1e-13, ...
    "coefficientRegeneration", 5e-15, "streaming", 5e-11, "beam", 1e-12, ...
    "cluster", 1e-12, ...
    "clusterFormula", "1e-12 + 64*eps(1)*abs(expected)");
end

function diagnostic = checkMigrationCase(identifier)
schedule = radardemo.schedule.createReceiveSchedule(struct());
schedule.schemaVersion = "1.0.0-draft.1";
switch identifier
    case "MIG-001"
        diagnostic = radardemo.conformance.validateArtifact("schedule", schedule);
    case "MIG-002"
        [~, diagnostic] = adaptWp4Draft1("schedule", schedule, ...
            struct("priSampleCounts", schedule.priSampleCounts, "transitionGapTicks", 106872));
    case "MIG-003"
        design = radardemo.ddc.createDesign(struct());
        [~, diagnostic] = adaptWp4Draft1("ddc", struct("schemaVersion", "1.0.0-draft.1"), ...
            struct("design", design));
    case "MIG-004"
        draft = struct("schemaVersion", "1.0.0-draft.1", "validityMask", true(1, 5), ...
            "supportMask", true(1, 5), "passMask", [true, true, true, false, false]);
        [migrated, diagnostic] = adaptWp4Draft1("fusion", draft, struct());
        if diagnostic.accepted && (~isfield(migrated, "migrationSeed") || migrated.migrationSeed ~= 401061)
            diagnostic = struct("accepted", false, "code", "VALUE_OUT_OF_RANGE", ...
                "path", "migrationSeed", "message", "Fusion migration seed is not recorded.", "output", struct());
        end
    case "MIG-005"
        draft = struct("schemaVersion", "1.0.0-draft.1", "hypotheses", ...
            struct("hypothesisId", "h1", "rangeM", 1, "radialVelocityMps", 1, ...
            "statistic", 1, "sourceCellIds", {{"p1:c1"}}));
        look = struct("hypothesisId", "h1", "azimuthLookIndex", 1, ...
            "elevationLookIndex", 1, "clusterCell", [1, 1], "clusterEligible", true, ...
            "validityMask", true(1, 5), "supportMask", true(1, 5), ...
            "passMask", true(1, 5));
        [~, diagnostic] = adaptWp4Draft1("clustering", draft, struct("commandedLooks", look));
    case "MIG-006"
        draft = struct("schemaVersion", "1.0.0-draft.1", "hypotheses", struct([]));
        [~, diagnostic] = adaptWp4Draft1("clustering", draft, struct());
    otherwise
        draft = struct("schemaVersion", "1.0.0-draft.1", "hypotheses", ...
            struct("hypothesisId", "h1", "rangeM", 1, "radialVelocityMps", 1, ...
            "statistic", 1, "sourceCellIds", {{"p1:c1"}}));
        look = struct("hypothesisId", "other", "azimuthLookIndex", 1, ...
            "elevationLookIndex", 1, "clusterCell", [1, 1], "clusterEligible", true);
        [~, diagnostic] = adaptWp4Draft1("clustering", draft, struct("commandedLooks", look));
end
diagnostic.output = struct();
end

function diagnostic = checkMetaCase(identifier, manifest, root)
if identifier == "META-001"
    rows = manifest.fixtures;
    repoRoot = fileparts(fileparts(fileparts(mfilename("fullpath"))));
    testText = fileread(fullfile(repoRoot, "tests", "wp4", "TestWp4Fixtures.m"));
    clausesResolve = true;
    methodsResolve = true;
    for rowIndex = 1:numel(rows)
        clauseParts = split(string(rows(rowIndex).clause), "#");
        clauseFile = fullfile(repoRoot, clauseParts(1));
        clausesResolve = clausesResolve && isfile(clauseFile);
        if clausesResolve
            document = fileread(clauseFile);
            clausesResolve = contains(document, "id=""" + clauseParts(2) + """") || ...
                contains(document, "#" + clauseParts(2));
        end
        methodsResolve = methodsResolve && contains(testText, "function " + string(rows(rowIndex).testMethod));
    end
    valid = numel(unique(string({rows.id}))) == numel(rows) && ...
        numel(unique(string({rows.testMethod}))) == numel(rows) && ...
        all(contains(string({rows.clause}), "#")) && ...
        all(strlength(string({rows.productionEntryPoint})) > 0) && ...
        all(isfield(rows, "provenanceSeed")) && ...
        isequal([manifest.seeds.master, manifest.seeds.schedule, manifest.seeds.ddc, ...
        manifest.seeds.beam, manifest.seeds.fusion, manifest.seeds.clustering, ...
        manifest.seeds.migration], [401002, 401011, 401021, 401031, 401041, 401051, 401061]) && ...
        all(arrayfun(@(row) isempty(row.artifact) || isfile(fullfile(root, string(row.artifact))), rows)) && ...
        clausesResolve && methodsResolve;
    if valid
        diagnostic = struct("accepted", true, "code", "", "path", "", ...
            "message", "Manifest traceability is complete.", "output", struct());
    else
        diagnostic = struct("accepted", false, "code", "VALUE_OUT_OF_RANGE", ...
            "path", "fixtures", "message", "Manifest traceability is incomplete.", "output", struct());
    end
else
    repoRoot = fileparts(fileparts(fileparts(mfilename("fullpath"))));
    sourceFiles = dir(fullfile(repoRoot, "src", "+radardemo", "**", "*.m"));
    generatorFiles = dir(fullfile(repoRoot, "contracts", "wp4", "+wp4gen", "**", "*.m"));
    oracleFiles = dir(fullfile(repoRoot, "contracts", "wp4", "+wp4oracle", "**", "*.m"));
    sourceText = readFiles(sourceFiles);
    generatorText = readFiles(generatorFiles);
    oracleText = readFiles(oracleFiles);
    sourceClean = all(~contains(sourceText, "contracts/wp4"));
    generatorClean = all(~contains(generatorText, "+wp4oracle")) && ...
        all(~contains(generatorText, "wp4oracle"));
    oracleClean = all(~contains(oracleText, "radardemo")) && ...
        all(~contains(oracleText, "wp4gen"));
    valid = sourceClean && generatorClean && oracleClean && ...
        any(contains(generatorText, "radardemo.ddc"));
    diagnostic = struct("accepted", valid, "code", "", "path", "", ...
        "message", "Generator and oracle dependency directions inspected.", "output", struct());
end

function text = readFiles(files)
text = strings(numel(files), 1);
for index = 1:numel(files)
    text(index) = lower(string(fileread(fullfile(files(index).folder, files(index).name))));
end
end
end

function merged = mergeOptions(defaults, supplied)
merged = defaults;
names = fieldnames(supplied);
for index = 1:numel(names)
    merged.(names{index}) = supplied.(names{index});
end
end

function data = loadArtifact(path)
if endsWith(path, ".json")
    data = jsondecode(fileread(path));
    return
end
loaded = load(path, "-mat");
names = fieldnames(loaded);
if numel(names) ~= 1
    error("wp4:MatEnvelope", "MAT fixture must contain one envelope variable.");
end
data = loaded.(names{1});
end

function output = matchesExpected(row, diagnostic)
expectedAccept = string(row.expected) == "accept";
if expectedAccept
    output = diagnostic.accepted;
    return
end
output = ~diagnostic.accepted && string(diagnostic.code) == string(row.expectedCode) && ...
    string(diagnostic.path) == string(row.expectedPath);
end

function data = applyMutations(data, mutations)
for index = 1:numel(mutations)
    mutation = mutations(index);
    if isfield(mutation, "valueKind") && string(mutation.valueKind) == "kaiser"
        beta = double(mutation.value);
        mutation.value = fir1(240, 5.625e6 / 25e6, kaiser(241, beta));
    elseif isfield(mutation, "valueKind") && string(mutation.valueKind) == "nan"
        mutation.value = NaN;
    end
    data = setPath(data, string(mutation.path), mutation.value);
end
end

function data = selectFusionCase(data, domain)
if domain == "fusion-zero" || ~contains(domain, "fusion-") || ~isfield(data, "cases")
    return
end
caseId = extractAfter(domain, "fusion-");
matches = string({data.cases.caseId}) == caseId;
if ~any(matches)
    error("wp4:FusionCase", "Fusion case is not present in the artifact.");
end
selected = data.cases(find(matches, 1));
selected.schemaName = data.schemaName;
selected.schemaVersion = data.schemaVersion;
data = selected;
end

function value = setPath(value, path, replacement)
tokens = regexp(char(path), "[A-Za-z_][A-Za-z0-9_]*(\[[0-9]+\])?", "match");
value = setPathTokens(value, tokens, 1, replacement);
end

function value = setPathTokens(value, tokens, tokenIndex, replacement)
if tokenIndex > numel(tokens)
    value = replacement;
    return
end
token = tokens{tokenIndex};
fieldName = regexprep(token, "\[[0-9]+\]", "");
if ~isstruct(value)
    error("wp4:MutationPath", "Mutation path does not address a struct field.");
end
if ~isfield(value, fieldName)
    error("wp4:MutationPath", "Mutation field does not exist: %s.", fieldName);
end
fieldValue = value.(fieldName);
indexToken = regexp(token, "\[([0-9]+)\]", "tokens", "once");
if ~isempty(indexToken)
    elementIndex = str2double(indexToken{1}) + 1;
    if elementIndex < 1 || elementIndex > numel(fieldValue)
        error("wp4:MutationPath", "Mutation index is outside the field.");
    end
    if tokenIndex == numel(tokens)
        if iscell(fieldValue)
            fieldValue{elementIndex} = replacement;
        else
            fieldValue(elementIndex) = replacement;
        end
    elseif iscell(fieldValue)
        fieldValue{elementIndex} = setPathTokens(fieldValue{elementIndex}, tokens, ...
            tokenIndex + 1, replacement);
    else
        fieldValue(elementIndex) = setPathTokens(fieldValue(elementIndex), tokens, ...
            tokenIndex + 1, replacement);
    end
else
    fieldValue = setPathTokens(fieldValue, tokens, tokenIndex + 1, replacement);
end
value.(fieldName) = fieldValue;
end
