function results = fuseFivePrf(hypotheses)
%FUSEFIVEPRF Fuse five projected PRF layers with the frozen 3-of-5 rule.
%   RESULTS = RADARDEMO.FUSION.FUSEFIVEPRF(HYPOTHESES) evaluates one or
%   more hypotheses carrying length-five validity, support, and pass masks.

arguments
    hypotheses struct
end

if isempty(hypotheses)
    results = struct([]);
    return
end
template = struct("validityMask", false(1, 5), "supportMask", false(1, 5), ...
    "passMask", false(1, 5), "voteCount", 0, "voteThreshold", 3, ...
    "outcome", "", "sourceCellIds", {{}});
results = repmat(template, numel(hypotheses), 1);
for index = 1:numel(hypotheses)
    current = hypotheses(index);
    required = ["validityMask", "supportMask", "passMask"];
    for fieldIndex = 1:numel(required)
        if ~isfield(current, required(fieldIndex))
            error("radardemo:fusion:MissingField", "Fusion mask field is required.");
        end
    end
    masks = {current.validityMask, current.supportMask, current.passMask};
    if any(cellfun(@(mask) numel(mask) ~= 5, masks))
        error("radardemo:fusion:MaskShape", "Fusion masks must have length five.");
    end
    validityMask = logical(current.validityMask(:).');
    supportMask = logical(current.supportMask(:).');
    passMask = logical(current.passMask(:).');
    if any(supportMask & ~validityMask)
        error("radardemo:fusion:SupportSubset", "Support must be a subset of validity.");
    end
    voteCount = sum(passMask);
    validCount = sum(validityMask);
    if validCount < 3
        outcome = "invalid";
    elseif voteCount >= 3
        outcome = "pass";
    else
        outcome = "fail";
    end
    results(index).validityMask = validityMask;
    results(index).supportMask = supportMask;
    results(index).passMask = passMask;
    results(index).voteCount = voteCount;
    results(index).outcome = char(outcome);
    if isfield(current, "sourceCellIds")
        results(index).sourceCellIds = current.sourceCellIds;
    else
        results(index).sourceCellIds = {};
    end
end
end
