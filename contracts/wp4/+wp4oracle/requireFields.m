function diagnostic = requireFields(data, fields, missingMessage)
%REQUIREFIELDS Return a diagnostic for the first missing structure field.
if nargin < 3
    missingMessage = "A required field is missing.";
end
diagnostic = wp4oracle.passDiagnostic();
for index = 1:numel(fields)
    if ~isstruct(data) || ~isfield(data, fields(index))
        diagnostic = wp4oracle.failDiagnostic("MISSING_FIELD", fields(index), missingMessage);
        return
    end
end
end
