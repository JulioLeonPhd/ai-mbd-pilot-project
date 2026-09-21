function report = generateWp4Fixtures(outputDirectory, options)
%GENERATEWP4FIXTURES Generate deterministic temporary WP4/G2 fixtures.
%   REPORT = GENERATEWP4FIXTURES(OUTPUTDIRECTORY) writes executable WP4/G2
%   evidence to OUTPUTDIRECTORY. The checker recomputes values independently.

arguments
    outputDirectory (1, 1) string
    options struct = struct()
end

if ~isfolder(outputDirectory)
    mkdir(outputDirectory);
end

defaults = struct("Seed", 401002, "GeneratorVersion", "wp4gen-1.0.0", ...
    "GeneratorRevision", "working-tree", "CreatedUtc", "", "WriteManifest", true, ...
    "Seeds", struct("master", 401002, "schedule", 401011, "ddc", 401021, ...
    "beam", 401031, "fusion", 401041, "clustering", 401051, "migration", 401061));
options = mergeOptions(defaults, options);

if strlength(options.CreatedUtc) == 0
    options.CreatedUtc = "1970-01-01T00:00:00Z";
end

schedule = wp4gen.generateSchedule(options);
ddc = wp4gen.generateDdc(options);
timing = wp4gen.generateTimingGate(schedule, options);
beam = wp4gen.generateBeamFixtures(options);
fusion = wp4gen.generateFusionFixtures(options);
clustering = wp4gen.generateClusteringFixtures(options);

writeJson(fullfile(outputDirectory, "schedule.json"), schedule);
writeMat(fullfile(outputDirectory, "timing-gate.mat"), "timingGate", timing);
writeMat(fullfile(outputDirectory, "ddc-design.mat"), "ddcDesign", ddc.design);
invalidRipple = ddc.design;
invalidRipple.stage2Numerator = fir1(240, 5.625e6 / 25e6, kaiser(241, 2));
writeMat(fullfile(outputDirectory, "ddc-ripple-invalid.mat"), "ddcDesign", invalidRipple);
invalidAlias = ddc.design;
invalidAlias.stage2Numerator = fir1(240, 5.625e6 / 25e6, kaiser(241, 5));
writeMat(fullfile(outputDirectory, "ddc-alias-invalid.mat"), "ddcDesign", invalidAlias);
writeMat(fullfile(outputDirectory, "ddc-streaming.mat"), "ddcStreaming", ddc.streaming);
writeMat(fullfile(outputDirectory, "ddc-zero.mat"), "ddcZero", ddc.zero);
writeMat(fullfile(outputDirectory, "beam-boresight.mat"), "beamFixture", beam.boresight);
writeMat(fullfile(outputDirectory, "beam-positive-30deg.mat"), "beamFixture", beam.positive);
writeMat(fullfile(outputDirectory, "beam-negative-30deg.mat"), "beamFixture", beam.negative);
writeMat(fullfile(outputDirectory, "beam-zero.mat"), "beamFixture", beam.zero);
writeJson(fullfile(outputDirectory, "fusion-cases.json"), fusion.cases);
writeJson(fullfile(outputDirectory, "fusion-zero.json"), fusion.zero);

clusterNames = fieldnames(clustering);
fileNames = ["clustering-single", "clustering-merge", "clustering-order", ...
    "clustering-no-wrap", "clustering-no-bridge", "clustering-cross-look", ...
    "clustering-duplicate-cell", "clustering-zero-empty", ...
    "clustering-zero-ineligible", "clustering-tie"];
for index = 1:numel(clusterNames)
    name = clusterNames{index};
    writeJson(fullfile(outputDirectory, fileNames(index) + ".json"), clustering.(name));
end

manifest = wp4gen.buildManifest(options);
if options.WriteManifest
    writeJson(fullfile(outputDirectory, "fixture-manifest.json"), manifest);
end

report = struct();
report.outputDirectory = char(outputDirectory);
report.manifestPath = char(fullfile(outputDirectory, "fixture-manifest.json"));
report.artifacts = {"schedule.json", "timing-gate.mat", "ddc-design.mat", ...
    "ddc-ripple-invalid.mat", "ddc-alias-invalid.mat", ...
    "ddc-streaming.mat", "ddc-zero.mat", "beam-boresight.mat", ...
    "beam-positive-30deg.mat", "beam-negative-30deg.mat", "beam-zero.mat", ...
    "fusion-cases.json", "fusion-zero.json"};
report.artifacts = [report.artifacts, cellstr(strcat(fileNames, ".json"))];
report.generatorVersion = char(options.GeneratorVersion);
report.generatorRevision = char(options.GeneratorRevision);
report.seed = options.Seed;
report.seeds = options.Seeds;
report.fixtureCount = numel(manifest.fixtures);
report.scope = "temporary-unit-evidence";
end

function merged = mergeOptions(defaults, supplied)
merged = defaults;
names = fieldnames(supplied);
for index = 1:numel(names)
    merged.(names{index}) = supplied.(names{index});
end
end

function writeJson(path, value)
jsonText = jsonencode(value, "PrettyPrint", true);
fileId = fopen(path, "w");
if fileId < 0
    error("wp4:FileOpen", "Unable to open JSON output %s.", path);
end
fwrite(fileId, jsonText, "char");
fclose(fileId);
end

function writeMat(path, variableName, value)
payload = struct();
payload.(variableName) = value;
save(path, "-struct", "payload", "-mat");
end
