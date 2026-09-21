function output = formCommandedLook(input, angleDeg, arraySpec)
%FORMCOMMANDEDLOOK Form a positive-radar-left commanded azimuth look.
%   OUTPUT = RADARDEMO.BEAMFORMING.FORMCOMMANDEDLOOK(INPUT, ANGLEDEG,
%   ARRAYSPEC) maps row-major [sample, azimuth, elevation] channels from
%   [N,64] to unnormalized coherent [N,4] elevation outputs.

arguments
    input double
    angleDeg (1, 1) double
    arraySpec struct = struct()
end

if ~ismatrix(input) || size(input, 2) ~= 64 || any(~isfinite(input), "all")
    error("radardemo:beamforming:InputShape", "Beam input must be finite [N,64].");
end
azimuthElements = getField(arraySpec, "azimuthElements", 16);
elevationElements = getField(arraySpec, "elevationElements", 4);
if azimuthElements ~= 16 || elevationElements ~= 4
    error("radardemo:beamforming:ArrayShape", "The frozen array shape is 16 by 4.");
end
elementIndex = reshape(0:azimuthElements - 1, 1, 1, []);
manifold = exp(-1i * 2 * pi * 0.5 * sind(angleDeg) * elementIndex);
reshaped = reshape(input, size(input, 1), elevationElements, azimuthElements);
output = sum(reshaped .* conj(manifold), 3);
end

function value = getField(data, name, fallback)
if isfield(data, name)
    value = data.(name);
else
    value = fallback;
end
end
