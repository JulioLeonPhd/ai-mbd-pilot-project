function diagnostic = failDiagnostic(code, path, message)
%FAILDIAGNOSTIC Create a rejected diagnostic with an empty output.
diagnostic = struct("accepted", false, "code", string(code), "path", string(path), ...
    "message", string(message), "output", struct());
end
