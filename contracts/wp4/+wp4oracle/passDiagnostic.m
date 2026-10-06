function diagnostic = passDiagnostic()
%PASSDIAGNOSTIC Create an accepted diagnostic with an empty output.
diagnostic = struct("accepted", true, "code", "", "path", "", "message", "", ...
    "output", struct());
end
