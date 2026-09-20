function report = check_mat_example(source)
%CHECK_MAT_EXAMPLE Check the canonical WP3 MAT test-vector envelope.
%   REPORT = CHECK_MAT_EXAMPLE() checks the repository MAT example.
%   REPORT = CHECK_MAT_EXAMPLE(PATH) checks a MAT file containing the
%   radarTestVector variable. REPORT = CHECK_MAT_EXAMPLE(STRUCT) checks an
%   in-memory radarTestVector struct, which is useful for negative checks.

if nargin == 0
    source = fullfile(fileparts(mfilename("fullpath")), "examples", ...
        "test-vector.mat");
end

examplesDirectory = fullfile(fileparts(mfilename("fullpath")), "examples");
report = struct( ...
    "status", "failed", ...
    "message", "WP3 MAT test-vector conformance failed", ...
    "source", "", ...
    "configurationSnapshot", fullfile(examplesDirectory, "configuration.json"), ...
    "scenarioSnapshot", fullfile(examplesDirectory, "scenario.json"), ...
    "diagnostics", emptyDiagnostic());
try
    if isstruct(source)
        vector = source;
        sourceDescription = "in-memory radarTestVector";
    elseif ischar(source) || (isstring(source) && isscalar(source))
        matPath = char(source);
        requireCondition(isfile(matPath), "source", ...
            "MAT file does not exist: " + string(matPath), "MISSING_FIELD");
        loaded = load(matPath, "radarTestVector");
        requireCondition(isfield(loaded, "radarTestVector"), "source", ...
            "MAT file must contain the radarTestVector variable", "MISSING_FIELD");
        vector = loaded.radarTestVector;
        sourceDescription = string(matPath);
    else
        requireCondition(false, "source", ...
            "expected a MAT-file path or radarTestVector struct", "TYPE_MISMATCH");
    end

    validateEnvelope(vector, examplesDirectory);
    report.status = "passed";
    report.message = "WP3 MAT test-vector example conforms to the checked subset";
    report.source = sourceDescription;
    fprintf("PASS: %s (%s)\n", report.message, sourceDescription);
catch exception
    report.diagnostics = exceptionDiagnostic(exception);
    if isstruct(source)
        report.source = "in-memory radarTestVector";
    elseif ischar(source) || (isstring(source) && isscalar(source))
        report.source = string(source);
    else
        report.source = "invalid source";
    end
    fprintf("FAIL: %s (%s)\n", report.diagnostics.message, report.source);
end
end

function validateEnvelope(vector, examplesDirectory)
requiredFields = { ...
    "schemaName", "schemaVersion", "documentVersion", "id", ...
    "createdUtc", "producer", "configurationId", ...
    "configurationSchemaVersion", "configurationDocumentVersion", ...
    "scenarioId", "scenarioSchemaVersion", "scenarioDocumentVersion", ...
    "configurationSnapshot", "scenarioSnapshot", "generatorRevision", ...
    "generatorVersion", "generatorSeed", "generationParameters", ...
    "sampleRateHz", "channelCount", "sampleFormat", "timeEpoch", ...
    "fixtureScope", "channelMap", "pulseRecords"};
allowedFields = [requiredFields, {"truth", "extensions"}];

requireCondition(isstruct(vector) && isscalar(vector), "radarTestVector", ...
    "must be a scalar struct", "TYPE_MISMATCH");
for index = 1:numel(requiredFields)
    fieldName = requiredFields{index};
    requireCondition(isfield(vector, fieldName), fieldName, ...
        "required field is missing", "MISSING_FIELD");
end
validateClosedFields(vector, allowedFields);

textFields = { ...
    "schemaName", "schemaVersion", "documentVersion", "id", ...
    "createdUtc", "producer", "configurationId", ...
    "configurationSchemaVersion", "configurationDocumentVersion", ...
    "scenarioId", "scenarioSchemaVersion", "scenarioDocumentVersion", ...
    "configurationSnapshot", "scenarioSnapshot", "generatorRevision", ...
    "generatorVersion", "sampleFormat", "timeEpoch", "fixtureScope"};
for index = 1:numel(textFields)
    validateTextField(vector, textFields{index});
end

requireCondition(strcmp(vector.schemaName, "radar.test-vector"), ...
    "schemaName", "must equal radar.test-vector", "VALUE_OUT_OF_RANGE");
requireCondition(strcmp(vector.schemaVersion, "1.0.0-draft.1"), ...
    "schemaVersion", "must equal 1.0.0-draft.1", "VERSION_MISMATCH");
requireCondition(strcmp(vector.documentVersion, "0.2.0"), ...
    "documentVersion", "must equal 0.2.0", "VERSION_MISMATCH");
requireCondition(strcmp(vector.configurationId, "g1-revised-candidate"), ...
    "configurationId", "must match the canonical configuration example", "PROVENANCE_MISMATCH");
requireCondition(strcmp(vector.scenarioId, "one-receding-target"), ...
    "scenarioId", "must match the canonical scenario example", "PROVENANCE_MISMATCH");
requireCondition(strcmp(vector.configurationSchemaVersion, ...
    "1.0.0-draft.1"), "configurationSchemaVersion", ...
    "must match the canonical configuration example", "VERSION_MISMATCH");
requireCondition(strcmp(vector.scenarioSchemaVersion, "1.0.0-draft.1"), ...
    "scenarioSchemaVersion", "must match the canonical scenario example", "VERSION_MISMATCH");
requireCondition(strcmp(vector.configurationDocumentVersion, "0.2.0"), ...
    "configurationDocumentVersion", "must match the canonical configuration example", "VERSION_MISMATCH");
requireCondition(strcmp(vector.scenarioDocumentVersion, "0.1.0"), ...
    "scenarioDocumentVersion", "must match the canonical scenario example", "VERSION_MISMATCH");
requireCondition(strcmp(vector.generatorVersion, "0.1.0"), "generatorVersion", ...
    "must match the canonical generator version", "VERSION_MISMATCH");
requireCondition(strcmp(vector.timeEpoch, "scan-start"), "timeEpoch", ...
    "must equal the canonical simulation-time epoch scan-start", "VALUE_OUT_OF_RANGE");
requireCondition(strcmp(vector.sampleFormat, "real-int16"), "sampleFormat", ...
    "must equal real-int16", "VALUE_OUT_OF_RANGE");
requireCondition(strcmp(vector.fixtureScope, "unit-only"), "fixtureScope", ...
    "canonical example must remain unit-only", "VALUE_OUT_OF_RANGE");

validateScalarValue(vector.sampleRateHz, "sampleRateHz", 150e6, "double");
validateScalarValue(vector.channelCount, "channelCount", 64, "double");
validateScalarValue(vector.generatorSeed, "generatorSeed", uint32(12345), "uint32");
requireCondition(isstruct(vector.generationParameters) && ...
    isscalar(vector.generationParameters), "generationParameters", ...
    "must be a scalar struct", "TYPE_MISMATCH");

configurationSnapshot = readUtf8File( ...
    fullfile(examplesDirectory, "configuration.json"));
scenarioSnapshot = readUtf8File( ...
    fullfile(examplesDirectory, "scenario.json"));
requireCondition(strcmp(vector.configurationSnapshot, configurationSnapshot), ...
    "configurationSnapshot", ...
    "must equal the exact UTF-8 configuration JSON snapshot", "PROVENANCE_MISMATCH");
requireCondition(strcmp(vector.scenarioSnapshot, scenarioSnapshot), ...
    "scenarioSnapshot", ...
    "must equal the exact UTF-8 scenario JSON snapshot", "PROVENANCE_MISMATCH");

validateChannelMap(vector.channelMap);
validatePulseRecords(vector.pulseRecords);
end

function validateTextField(vector, fieldName)
value = vector.(fieldName);
requireCondition(ischar(value) && isrow(value) && ~isempty(value), fieldName, ...
    "must be a non-empty character row vector", "TYPE_MISMATCH");
end

function validateClosedFields(value, allowedFields)
fieldNames = fieldnames(value);
for index = 1:numel(fieldNames)
    fieldName = fieldNames{index};
    requireCondition(any(strcmp(string(allowedFields), string(fieldName))), fieldName, ...
        "unknown field is not permitted by the closed schema", ...
        "VALUE_OUT_OF_RANGE");
end
end

function validateScalarValue(value, fieldName, expectedValue, expectedClass)
requireCondition(isa(value, expectedClass), fieldName, ...
    "must have class " + string(expectedClass), "TYPE_MISMATCH");
requireCondition(isscalar(value), fieldName, ...
    "must be a scalar", "DIMENSION_MISMATCH");
requireCondition(isreal(value), fieldName, ...
    "must be real", "TYPE_MISMATCH");
requireCondition(isfinite(value), fieldName, ...
    "must be finite", "NONFINITE");
requireCondition(isequal(value, expectedValue), fieldName, ...
    "must equal " + string(expectedValue), "VALUE_OUT_OF_RANGE");
end

function validateChannelMap(channelMap)
azimuthIndex = repelem((1:16)', 4, 1);
elevationIndex = repmat((1:4)', 16, 1);
expectedMap = uint8([azimuthIndex, elevationIndex]);
requireCondition(isa(channelMap, "uint8"), "channelMap", ...
    "must have class uint8", "TYPE_MISMATCH");
requireCondition(isequal(size(channelMap), [64, 2]), ...
    "channelMap", "must be a 64x2 matrix", "DIMENSION_MISMATCH");
requireCondition(isequal(channelMap, expectedMap), "channelMap", ...
    "must map channels row-major from azimuth 1..16 and elevation 1..4", "VALUE_OUT_OF_RANGE");
end

function validatePulseRecords(records)
recordFields = { ...
    "adcSamples", "adcTick", "pulseStartTick", "pulseSampleCount", ...
    "prfIndex", "prfNominalHz"};
requireCondition(isstruct(records) && isscalar(records), "pulseRecords", ...
    "canonical example must contain one scalar record", "DIMENSION_MISMATCH");
validateClosedFields(records, [recordFields, {"isTransition", "truth", "extensions"}]);
for index = 1:numel(recordFields)
    fieldName = recordFields{index};
    requireCondition(isfield(records, fieldName), "pulseRecords." + string(fieldName), ...
        "required field is missing", "MISSING_FIELD");
end

samples = records.adcSamples;
requireCondition(isa(samples, "int16"), "pulseRecords.adcSamples", ...
    "must have class int16", "TYPE_MISMATCH");
requireCondition(isequal(size(samples), [32, 64]), ...
    "pulseRecords.adcSamples", "must be a 32x64 matrix", "DIMENSION_MISMATCH");
requireCondition(all(samples(:) == 0), "pulseRecords.adcSamples", ...
    "canonical shape fixture must contain zero-valued samples", "VALUE_OUT_OF_RANGE");

ticks = records.adcTick;
requireCondition(isa(ticks, "uint64"), "pulseRecords.adcTick", ...
    "must have class uint64", "TYPE_MISMATCH");
requireCondition(isequal(size(ticks), [32, 1]), ...
    "pulseRecords.adcTick", "must be a 32x1 vector", "DIMENSION_MISMATCH");
requireCondition(isequal(ticks, uint64((0:31)')), "pulseRecords.adcTick", ...
    "must contain the monotonic global ticks 0 through 31", "TICK_DISCONTINUITY");

validateScalarValue(records.pulseStartTick, "pulseRecords.pulseStartTick", uint64(0), "uint64");
validateScalarValue(records.pulseSampleCount, "pulseRecords.pulseSampleCount", uint32(32), "uint32");
requireCondition(records.pulseSampleCount == size(samples, 1), ...
    "pulseRecords.pulseSampleCount", "must equal the ADC sample-row count", ...
    "DIMENSION_MISMATCH");
validateScalarValue(records.prfIndex, "pulseRecords.prfIndex", uint8(1), "uint8");
validateScalarValue(records.prfNominalHz, "pulseRecords.prfNominalHz", 1700, "double");
end

function text = readUtf8File(filePath)
fileId = fopen(filePath, "r");
requireCondition(fileId >= 0, "snapshot", "cannot open " + string(filePath), "MISSING_FIELD");
cleanup = onCleanup(@() fclose(fileId));
bytes = fread(fileId, Inf, "*uint8")';
text = native2unicode(bytes, "UTF-8");
clear cleanup
end

function diagnostic = emptyDiagnostic()
diagnostic = struct("code", "", "path", "", "message", "");
end

function diagnostic = exceptionDiagnostic(exception)
identifierParts = split(string(exception.identifier), ":");
code = identifierParts(end);
messageParts = regexp(char(exception.message), "^([^:]+): (.*)$", "tokens", "once");
if isempty(messageParts)
    fieldPath = "source";
    message = string(exception.message);
else
    fieldPath = string(messageParts{1});
    message = string(messageParts{2});
end
diagnostic = struct("code", code, "path", fieldPath, "message", message);
end

function requireCondition(condition, fieldPath, message, code)
if ~condition
    if nargin < 4 || isempty(code)
        error("WP3:check_mat_example:TYPE_MISMATCH", ...
            "%s: missing explicit diagnostic code", char(fieldPath));
    end
    error("WP3:check_mat_example:" + string(code), "%s: %s", ...
        char(fieldPath), char(message));
end
end
