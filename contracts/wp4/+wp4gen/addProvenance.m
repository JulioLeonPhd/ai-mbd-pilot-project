function artifact = addProvenance(artifact, options, generatorSeed, domain)
%ADDPROVENANCE Attach explicit generator provenance to one fixture envelope.
%   This helper is generator-only metadata plumbing; it performs no numeric
%   calculations and is not used by production or oracle code.

arguments
    artifact struct
    options struct
    generatorSeed (1, 1) double
    domain (1, 1) string
end

artifact.generatorRevision = char(options.GeneratorRevision);
artifact.generatorVersion = char(options.GeneratorVersion);
artifact.generatorSeed = generatorSeed;
artifact.generationParameters = struct("fixtureScope", char(options.FixtureScope), ...
    "domain", char(domain));
artifact.createdUtc = char(options.CreatedUtc);
end
