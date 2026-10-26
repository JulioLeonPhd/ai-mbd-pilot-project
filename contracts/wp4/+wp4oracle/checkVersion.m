function diagnostic = checkVersion(data)
%CHECKVERSION Validate the package evidence schema version.
if ~isstruct(data) || ~isfield(data, "schemaVersion")
    diagnostic = wp4oracle.failDiagnostic("MISSING_FIELD", "schemaVersion", ...
        "Schema version is required.");
elseif string(data.schemaVersion) ~= "1.0.0-draft.2"
    diagnostic = wp4oracle.failDiagnostic("VERSION_MISMATCH", "schemaVersion", ...
        "Only schema 1.0.0-draft.2 is accepted.");
else
    diagnostic = wp4oracle.passDiagnostic();
end
end
