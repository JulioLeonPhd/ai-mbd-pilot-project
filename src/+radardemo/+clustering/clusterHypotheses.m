function clusters = clusterHypotheses(hypotheses)
%CLUSTERHYPOTHESES Aggregate eligible same-look adjacent hypotheses.
%   CLUSTERS = RADARDEMO.CLUSTERING.CLUSTERHYPOTHESES(HYPOTHESES) computes
%   connected components using one-cell Chebyshev adjacency without wrapping
%   or ineligible bridging. No winning member identity is stored.

arguments
    hypotheses struct
end

if isempty(hypotheses)
    clusters = struct([]);
    return
end
eligible = find([hypotheses.clusterEligible]);
if isempty(eligible)
    clusters = struct([]);
    return
end
visited = false(size(eligible));
components = cell(0, 1);
for index = 1:numel(eligible)
    if visited(index)
        continue
    end
    queue = index;
    visited(index) = true;
    component = index;
    while ~isempty(queue)
        current = queue(1);
        queue(1) = [];
        for candidate = 1:numel(eligible)
            if visited(candidate)
                continue
            end
            left = hypotheses(eligible(current));
            right = hypotheses(eligible(candidate));
            sameLook = left.azimuthLookIndex == right.azimuthLookIndex && ...
                left.elevationLookIndex == right.elevationLookIndex;
            adjacent = max(abs(left.clusterCell - right.clusterCell)) <= 1;
            if sameLook && adjacent
                visited(candidate) = true;
                queue(end + 1) = candidate; %#ok<AGROW>
                component(end + 1) = candidate; %#ok<AGROW>
            end
        end
    end
    components{end + 1} = eligible(component); %#ok<AGROW>
end
componentKeys = strings(numel(components), 1);
for index = 1:numel(components)
    members = orderMembers(hypotheses(components{index}));
    componentKeys(index) = memberKey(members(1));
end
[~, componentOrder] = sort(componentKeys);
components = components(componentOrder);
template = struct("clusterId", 0, "hypothesisIds", {{}}, "rangeM", 0, ...
    "radialVelocityMps", 0, "statistic", 0, "validityMask", false(1, 5), ...
    "supportMask", false(1, 5), "passMask", false(1, 5), "sourceCellIds", {{}});
clusters = repmat(template, numel(components), 1);
for index = 1:numel(components)
    members = hypotheses(components{index});
    members = orderMembers(members);
    clusters(index).clusterId = index;
    clusters(index).hypothesisIds = {members.hypothesisId};
    clusters(index).rangeM = mean([members.rangeM]);
    clusters(index).radialVelocityMps = mean([members.radialVelocityMps]);
    clusters(index).statistic = max([members.statistic]);
    clusters(index).validityMask = mergeMask(members, "validityMask");
    clusters(index).supportMask = mergeMask(members, "supportMask");
    clusters(index).passMask = mergeMask(members, "passMask");
    clusters(index).sourceCellIds = cellstr(sort(unique(string([members.sourceCellIds]))));
end
end

function members = orderMembers(members)
keys = strings(numel(members), 1);
for index = 1:numel(members)
    sourceIds = sort(stringList(members(index).sourceCellIds));
    keys(index) = strjoin([sourceIds; string(members(index).hypothesisId)], "|");
end
[~, order] = sort(keys);
members = members(order);
end

function key = memberKey(member)
sourceIds = sort(stringList(member.sourceCellIds));
key = strjoin([sourceIds; string(member.hypothesisId)], "|");
end

function output = mergeMask(members, name)
if ~isfield(members, name)
    output = false(1, 5);
    return
end
output = false(1, 5);
for index = 1:numel(members)
    mask = members(index).(name);
    if numel(mask) ~= 5
        error("radardemo:clustering:MaskShape", "Member masks must have length five.");
    end
    output = output | logical(mask(:).');
end
end

function output = stringList(value)
output = string(value);
end
