function beam = generateBeamFixtures(options)
%GENERATEBEAMFIXTURES Record production beamforming observations.

arguments
    options struct
end

beam.boresight = makeFixture(0, 1, options);
beam.positive = makeFixture(30, 2, options);
beam.negative = makeFixture(-30, 3, options);
zero = makeFixture(0, 4, options);
zero.input = complex(zeros(2, 64));
zero.expectedOutput = complex(zeros(2, 4));
beam.zero = zero;
end

function fixture = makeFixture(commandAngleDeg, fixtureIndex, options)
azimuth = (0:15).';
manifold = exp(-1i * 2 * pi * 0.5 * azimuth * sind(commandAngleDeg));
input = zeros(2, 64);
for azimuthIndex = 1:16
    channels = (azimuthIndex - 1) * 4 + (1:4);
    input(:, channels) = manifold(azimuthIndex);
end
expectedOutput = radardemo.beamforming.formCommandedLook(input, commandAngleDeg, struct());
fixture = struct();
fixture.schemaName = "radar.wp4.beamforming";
fixture.schemaVersion = "1.0.0-draft.2";
fixture.inputShape = size(input);
fixture.outputShape = size(expectedOutput);
fixture.azimuthLookIndex = fixtureIndex;
fixture.commandAngleDeg = commandAngleDeg;
fixture.elevationRows = 4;
fixture.azimuthElementsPerRow = 16;
fixture.normalization = "none";
fixture.signConvention = "positive-radar-left";
fixture.input = input;
fixture.expectedOutput = expectedOutput;
fixture.tolerance = 1e-12;
fixture.seed = options.Seeds.beam;
end
