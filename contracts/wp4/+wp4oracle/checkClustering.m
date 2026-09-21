function diagnostic = checkClustering(data)
%CHECKCLUSTERING Independently recompute canonical Chebyshev aggregates.

diagnostic = checkVersion(data);
if ~diagnostic.accepted
    return
end
if ~isfield(data, "hypotheses") || ~isfield(data, "clusters")
    diagnostic = failDiagnostic("MISSING_FIELD", "clusters", ...
        "Clustering fixture must include hypotheses and complete aggregates.");
    return
end
hypotheses = data.hypotheses;
if isempty(hypotheses)
    if isempty(data.clusters)
        diagnostic = passDiagnostic();
    else
        diagnostic = failDiagnostic("NUMERICAL_MISMATCH", "clusters", ...
            "An empty hypothesis set must have no clusters.");
    end
    return
end
requiredHypothesis = ["hypothesisId", "clusterEligible", "azimuthLookIndex", ...
    "elevationLookIndex", "clusterCell", "rangeM", "radialVelocityMps", ...
    "statistic", "validityMask", "supportMask", "passMask", "sourceCellIds"];
for hypothesisIndex = 1:numel(hypotheses)
    missing = requiredHypothesis(~isfield(hypotheses(hypothesisIndex), requiredHypothesis));
    if ~isempty(missing)
        diagnostic = failDiagnostic("MISSING_FIELD", ...
            "hypotheses[" + string(hypothesisIndex - 1) + "]." + missing(1), ...
            "Hypothesis fields are required for independent aggregation.");
        return
    end
    if any([numel(hypotheses(hypothesisIndex).validityMask), ...
            numel(hypotheses(hypothesisIndex).supportMask), ...
            numel(hypotheses(hypothesisIndex).passMask)] ~= 5)
        diagnostic = failDiagnostic("DIMENSION_MISMATCH", ...
            "hypotheses[" + string(hypothesisIndex - 1) + "].validityMask", ...
            "Hypothesis masks must have length five.");
        return
    end
end
expected = recomputeAggregates(hypotheses);
if numel(data.clusters) ~= numel(expected)
    diagnostic = failDiagnostic("NUMERICAL_MISMATCH", "clusters", ...
        "Stored aggregate count differs from recomputation.");
    return
end
allIds = string({hypotheses.hypothesisId});
for clusterIndex = 1:numel(expected)
    stored = data.clusters(clusterIndex);
    requiredCluster = ["clusterId", "hypothesisIds", "rangeM", ...
        "radialVelocityMps", "statistic", "validityMask", "supportMask", ...
        "passMask", "sourceCellIds"];
    missing = requiredCluster(~isfield(stored, requiredCluster));
    if ~isempty(missing)
        diagnostic = failDiagnostic("MISSING_FIELD", ...
            "clusters[" + string(clusterIndex - 1) + "]." + missing(1), ...
            "Complete aggregate fields are required.");
        return
    end
    storedIds = string(stored.hypothesisIds(:));
    if any(~ismember(storedIds, allIds))
        unknownIndex = find(~ismember(storedIds, allIds), 1);
        diagnostic = failDiagnostic("VALUE_OUT_OF_RANGE", ...
            "clusters[" + string(clusterIndex - 1) + "].hypothesisIds[" + ...
            string(unknownIndex - 1) + "]", "Aggregate references an unknown hypothesis.");
        return
    end
    expectedIds = string(expected(clusterIndex).hypothesisIds(:));
    if stored.clusterId ~= expected(clusterIndex).clusterId || ...
            ~isequal(storedIds, expectedIds)
        diagnostic = failDiagnostic("NUMERICAL_MISMATCH", ...
            "clusters[" + string(clusterIndex - 1) + "].clusterId", ...
            "Aggregate identifier or canonical member order differs.");
        return
    end
    rangeTolerance = 1e-12 + 64 * eps(1) * abs(expected(clusterIndex).rangeM);
    velocityTolerance = 1e-12 + 64 * eps(1) * abs(expected(clusterIndex).radialVelocityMps);
    if abs(stored.rangeM - expected(clusterIndex).rangeM) > rangeTolerance || ...
            abs(stored.radialVelocityMps - expected(clusterIndex).radialVelocityMps) > velocityTolerance || ...
            stored.statistic ~= expected(clusterIndex).statistic
        diagnostic = failDiagnostic("NUMERICAL_MISMATCH", ...
            "clusters[" + string(clusterIndex - 1) + "].rangeM", ...
            "Aggregate means or maximum statistic differ from canonical arithmetic.");
        return
    end
    if ~isequal(logical(stored.validityMask(:).'), expected(clusterIndex).validityMask) || ...
            ~isequal(logical(stored.supportMask(:).'), expected(clusterIndex).supportMask) || ...
            ~isequal(logical(stored.passMask(:).'), expected(clusterIndex).passMask)
        diagnostic = failDiagnostic("NUMERICAL_MISMATCH", ...
            "clusters[" + string(clusterIndex - 1) + "].validityMask", ...
            "Aggregate masks differ from member OR masks.");
        return
    end
    storedSourceIds = sort(string(stored.sourceCellIds(:)));
    expectedSourceIds = sort(string(expected(clusterIndex).sourceCellIds(:)));
    if ~isequal(storedSourceIds, expectedSourceIds)
        diagnostic = failDiagnostic("NUMERICAL_MISMATCH", ...
            "clusters[" + string(clusterIndex - 1) + "].sourceCellIds", ...
            "Aggregate source-cell provenance differs from member provenance.");
        return
    end
end
diagnostic = passDiagnostic();
end

function aggregates = recomputeAggregates(hypotheses)
eligible = find([hypotheses.clusterEligible]);
if isempty(eligible)
    aggregates = struct([]);
    return
end
% Build connected components with a disjoint-set pass, independent of the
% production queue traversal.
parent = 1:numel(eligible);
for leftIndex = 1:numel(eligible)
    for rightIndex = leftIndex + 1:numel(eligible)
        left = hypotheses(eligible(leftIndex));
        right = hypotheses(eligible(rightIndex));
        sameLook = left.azimuthLookIndex == right.azimuthLookIndex && ...
            left.elevationLookIndex == right.elevationLookIndex;
        adjacent = max(abs(left.clusterCell - right.clusterCell)) <= 1;
        if sameLook && adjacent
            parent = unionSets(parent, leftIndex, rightIndex);
        end
    end
end
roots = zeros(1, numel(eligible));
for index = 1:numel(eligible)
    roots(index) = findRoot(parent, index);
end
uniqueRoots = unique(roots, "stable");
components = cell(numel(uniqueRoots), 1);
for componentIndex = 1:numel(uniqueRoots)
    components{componentIndex} = eligible(roots == uniqueRoots(componentIndex));
end
keys = strings(numel(components), 1);
for index = 1:numel(components)
    members = canonicalMembers(hypotheses(components{index}));
    keys(index) = memberKey(members(1));
end
[~, ordering] = sort(keys);
components = components(ordering);
template = struct("clusterId", 0, "hypothesisIds", {{}}, "rangeM", 0, ...
    "radialVelocityMps", 0, "statistic", 0, "validityMask", false(1, 5), ...
    "supportMask", false(1, 5), "passMask", false(1, 5), "sourceCellIds", {{}});
aggregates = repmat(template, numel(components), 1);
for index = 1:numel(components)
    members = canonicalMembers(hypotheses(components{index}));
    aggregates(index).clusterId = index;
    aggregates(index).hypothesisIds = {members.hypothesisId};
    aggregates(index).rangeM = mean([members.rangeM]);
    aggregates(index).radialVelocityMps = mean([members.radialVelocityMps]);
    aggregates(index).statistic = max([members.statistic]);
    aggregates(index).validityMask = orMask(members, "validityMask");
    aggregates(index).supportMask = orMask(members, "supportMask");
    aggregates(index).passMask = orMask(members, "passMask");
    aggregates(index).sourceCellIds = cellstr(sort(unique(string([members.sourceCellIds]))));
end
end

function parent = unionSets(parent, left, right)
leftRoot = findRoot(parent, left);
rightRoot = findRoot(parent, right);
if leftRoot ~= rightRoot
    parent(rightRoot) = leftRoot;
end
end

function root = findRoot(parent, index)
root = index;
while parent(root) ~= root
    root = parent(root);
end
end

function members = canonicalMembers(members)
keys = strings(numel(members), 1);
for index = 1:numel(members)
    keys(index) = memberKey(members(index));
end
[~, order] = sort(keys);
members = members(order);
end

function key = memberKey(member)
key = strjoin([sort(string(member.sourceCellIds(:))); string(member.hypothesisId)], "|");
end

function mask = orMask(members, fieldName)
mask = false(1, 5);
for index = 1:numel(members)
    mask = mask | logical(members(index).(fieldName)(:).');
end
end

function diagnostic = checkVersion(data)
if ~isstruct(data) || ~isfield(data, "schemaVersion")
    diagnostic = failDiagnostic("MISSING_FIELD", "schemaVersion", "Schema version is required.");
elseif string(data.schemaVersion) ~= "1.0.0-draft.2"
    diagnostic = failDiagnostic("VERSION_MISMATCH", "schemaVersion", ...
        "Only schema 1.0.0-draft.2 is accepted.");
else
    diagnostic = passDiagnostic();
end
end

function diagnostic = passDiagnostic()
diagnostic = struct("accepted", true, "code", "", "path", "", "message", "", ...
    "output", struct());
end

function diagnostic = failDiagnostic(code, path, message)
diagnostic = struct("accepted", false, "code", string(code), "path", string(path), ...
    "message", string(message), "output", struct());
end
