function clustering = generateClusteringFixtures(options)
%GENERATECLUSTERINGFIXTURES Record production clustering aggregates.

arguments
    options struct
end

clustering.clusteringSingle = makeDocument([makeHypothesis("h1", 1, 1, 1, ...
    1000, 2, 4, "p1:c1")], options);
clustering.clusteringMerge = makeDocument([makeHypothesis("h1", 1, 1, 1, ...
    1, 1, 1, "p1:c1"), makeHypothesis("h2", 1, 1, 2, 3, 3, 2, "p2:c1")], options);
orderHypotheses = [makeHypothesis("h2", 1, 1, 2, 3, 3, 2, "p2:c1"), ...
    makeHypothesis("h1", 1, 1, 1, 1, 1, 1, "p1:c1")];
clustering.clusteringOrder = makeDocument(orderHypotheses, options);
clustering.clusteringNoWrap = makeDocument([makeHypothesis("h1", 1, 1, 1, ...
    1, 1, 1, "p1:c1"), makeHypothesis("h2", 1, 1, 10, 2, 2, 1, "p2:c1")], options);
bridge = [makeHypothesis("h1", 1, 1, 1, 1, 1, 1, "p1:c1"), ...
    makeHypothesis("h2", 1, 1, 2, 2, 2, 1, "p2:c1"), ...
    makeHypothesis("h3", 1, 1, 3, 3, 3, 1, "p3:c1")];
bridge(2).clusterEligible = false;
clustering.clusteringNoBridge = makeDocument(bridge, options);
clustering.clusteringCrossLook = makeDocument([makeHypothesis("h1", 1, 1, 1, ...
    1, 1, 1, "p1:c1"), makeHypothesis("h2", 2, 1, 1, 1, 1, 1, "p2:c1")], options);
duplicate = [makeHypothesis("h1", 1, 1, 1, 1, 1, 1, "p1:c1"), ...
    makeHypothesis("h2", 1, 1, 1, 3, 3, 2, "p2:c1")];
clustering.clusteringDuplicateCell = makeDocument(duplicate, options);
clustering.clusteringZeroEmpty = makeDocument(struct([]), options);
ineligible = makeHypothesis("h1", 1, 1, 1, 1, 1, 1, "p1:c1");
ineligible.clusterEligible = false;
clustering.clusteringZeroIneligible = makeDocument(ineligible, options);
tie = [makeHypothesis("h2", 1, 1, 2, 3, 3, 4, "p2:c1"), ...
    makeHypothesis("h1", 1, 1, 1, 1, 1, 4, "p1:c1")];
clustering.clusteringTie = makeDocument(tie, options);
end

function document = makeDocument(hypotheses, options)
document = struct();
document.schemaName = "radar.wp4.clustering";
document.schemaVersion = "1.0.0-draft.2";
document.hypotheses = hypotheses;
document.clusters = radardemo.clustering.clusterHypotheses(hypotheses);
document.seed = options.Seeds.clustering;
end

function hypothesis = makeHypothesis(identifier, azimuth, elevation, rangeCell, ...
    rangeM, velocityMps, statistic, sourceCellId)
hypothesis = struct("hypothesisId", identifier, "clusterEligible", true, ...
    "azimuthLookIndex", azimuth, "elevationLookIndex", elevation, ...
    "clusterCell", [rangeCell, 1], "rangeM", rangeM, ...
    "radialVelocityMps", velocityMps, "statistic", statistic, ...
    "validityMask", true(1, 5), "supportMask", true(1, 5), ...
    "passMask", true(1, 5), "sourceCellIds", {{sourceCellId}});
end
