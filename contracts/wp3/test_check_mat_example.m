function tests = test_check_mat_example
%TEST_CHECK_MAT_EXAMPLE Exercise structured WP3 MAT conformance diagnostics.
tests = functiontests(localfunctions);
end

function testCanonicalExamplePasses(testCase)
vector = loadCanonicalVector();
report = check_mat_example(vector);
verifyEqual(testCase, report.status, "passed");
verifyEqual(testCase, report.diagnostics.code, "");
end

function testManifestMatRows(testCase)
root = fileparts(mfilename("fullpath"));
manifest = jsondecode(fileread(fullfile(root, "fixture-manifest.json")));
rows = manifest.fixtures;
for index = 1:numel(rows)
    row = rows(index);
    if ~isfield(row, "tool") || ~strcmp(string(row.tool), "matlab")
        continue
    end
    vector = applyManifestMutation(loadCanonicalVector(), row.mutation);
    report = check_mat_example(vector);
    if strcmp(string(row.expected), "accept")
        verifyEqual(testCase, report.status, "passed", string(row.id));
    elseif strcmp(string(row.expected), "reject")
        verifyEqual(testCase, report.status, "failed", string(row.id));
        verifyEqual(testCase, report.diagnostics.code, string(row.expectedCode), string(row.id));
        verifyEqual(testCase, report.diagnostics.path, string(row.expectedPath), string(row.id));
    else
        verifyTrue(testCase, any(strcmp(string(row.expected), ["not-applicable", "skip"])), string(row.id));
    end
end
end

function vector = loadCanonicalVector()
root = fileparts(mfilename("fullpath"));
loaded = load(fullfile(root, "examples", "test-vector.mat"), "radarTestVector");
vector = loaded.radarTestVector;
end

function value = applyManifestMutation(value, mutation)
if isempty(mutation)
    return
end
operation = string(mutation.operation);
path = split(string(mutation.path), ".");
if operation == "remove"
    value = removeAtPath(value, path, 1);
elseif operation == "replace"
    value = replaceAtPath(value, path, 1, mutation.value);
elseif operation == "reshape"
    value = reshapeAtPath(value, path, 1, mutation.value);
elseif operation == "duplicate"
    value = duplicateAtPath(value, path, 1);
elseif operation == "add"
    value = addAtPath(value, path, 1, mutation.value);
elseif operation == "replace-element"
    value = replaceElementAtPath(value, path, 1, mutation.indices, mutation.value);
else
    error("WP3:test_check_mat_example:UnsupportedMutation", ...
        "Unsupported manifest mutation: %s", operation);
end
end

function value = addAtPath(value, path, position, newValue)
fieldName = char(path(position));
if position == numel(path)
    value.(fieldName) = newValue;
else
    value.(fieldName) = addAtPath(value.(fieldName), path, position + 1, newValue);
end
end

function value = replaceElementAtPath(value, path, position, indices, replacement)
fieldName = char(path(position));
if position == numel(path)
    original = value.(fieldName);
    indexValues = num2cell(double(indices(:)'));
    original(indexValues{:}) = cast(replacement, "like", original);
    value.(fieldName) = original;
else
    value.(fieldName) = replaceElementAtPath( ...
        value.(fieldName), path, position + 1, indices, replacement);
end
end

function value = duplicateAtPath(value, path, position)
if position == numel(path)
    fieldName = char(path(position));
    value.(fieldName) = repmat(value.(fieldName), 1, 2);
else
    fieldName = char(path(position));
    value.(fieldName) = duplicateAtPath(value.(fieldName), path, position + 1);
end
end

function value = removeAtPath(value, path, position)
fieldName = char(path(position));
if position == numel(path)
    value = rmfield(value, fieldName);
else
    value.(fieldName) = removeAtPath(value.(fieldName), path, position + 1);
end
end

function value = replaceAtPath(value, path, position, replacement)
fieldName = char(path(position));
if position == numel(path)
    original = value.(fieldName);
    if ischar(original)
        value.(fieldName) = char(string(replacement));
    else
        value.(fieldName) = replacement;
    end
else
    value.(fieldName) = replaceAtPath(value.(fieldName), path, position + 1, replacement);
end
end

function value = reshapeAtPath(value, path, position, dimensions)
fieldName = char(path(position));
if position == numel(path)
    original = value.(fieldName);
    sizeValue = double(dimensions(:)');
    value.(fieldName) = zeros(sizeValue, class(original));
else
    value.(fieldName) = reshapeAtPath(value.(fieldName), path, position + 1, dimensions);
end
end
