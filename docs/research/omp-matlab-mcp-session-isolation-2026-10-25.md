# OMP parallel MATLAB MCP session-isolation pilot

## Purpose and status

This note records a bounded observation of concurrent OMP specialist tasks calling the MATLAB disposable MCP endpoint, and a separate executable-copy experiment supplied by the root orchestrator. It distinguishes directly observed process/workspace evidence from explanations that remain unproven.

The observations were collected on 2026-10-25.

This is pilot runtime research, not an approved architecture decision, product implementation, or acceptance gate. ADR 0023's AI-infrastructure freeze remains in force; no runtime/configuration change is proposed or authorized here. The active radar milestone in `CURRENT.md` is unchanged.

## Question and runtime boundary

The question was whether concurrently dispatched OMP roles making nominally separate MATLAB disposable MCP calls actually received separate MATLAB processes/workspaces. Three different kinds of concurrency must not be conflated:

| Layer                        | What it means here                                                                              | What this observation says                                                                                                                                                                                                                                                                                                                                                      |
| ---------------------------- | ----------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Agent concurrency            | Multiple OMP task roles run at once.                                                            | Six standard roles were dispatched in one active-session batch.                                                                                                                                                                                                                                                                                                                 |
| MCP request concurrency      | Multiple requests reach a server/tool endpoint during overlapping agent work.                   | Role outputs overlapped or contained cross-role material; this is not a general throughput or ordering measurement.                                                                                                                                                                                                                                                             |
| MATLAB execution parallelism | MATLAB computations run simultaneously, including through MATLAB parallel-computing facilities. | Not measured: the six-agent shared-server batch did not validate MATLAB computation parallelism. Later, two distinct MATLAB processes had overlapping evaluation-call intervals in the bounded executable-copy experiment; this establishes concurrent calls across processes for that trial, not MATLAB Parallel Computing Toolbox behavior or broader computation throughput. |

At pinned OMP source revision [v18.12.6](https://github.com/can1357/oh-my-pi/tree/v18.12.6/packages/coding-agent/src/task), [`createMCPProxyTools`](https://github.com/can1357/oh-my-pi/blob/v18.12.6/packages/coding-agent/src/task/executor.ts#L960-L980) builds child tools from the supplied `MCPManager`, and task execution passes `options.mcpManager` into subagent options ([executor source](https://github.com/can1357/oh-my-pi/blob/v18.12.6/packages/coding-agent/src/task/executor.ts#L4570-L4572) and [MCP option propagation](https://github.com/can1357/oh-my-pi/blob/v18.12.6/packages/coding-agent/src/task/executor.ts#L4670-L4672)). This supports the description that child tool calls are forwarded through the parent manager; it does not by itself establish MATLAB server process/session behavior.

## Environment and evidence provenance

The recorded environment was OMP v18.12.6, MATLAB MCP v0.15.0, MATLAB R2026a Update 5, and macOS 26.6.2. The OS version and installed product versions are from the prior runtime observation and were not independently re-verified for this note. The parent MATLAB PID reported in that observation was `52595`.

The OMP source link is revision-pinned. The MATLAB MCP source inspected was the installed local toolkit at `/Users/julio/Library/Application Support/MathWorks/Agentic Toolkits/v1/toolkits/matlab-mcp-server`; it was not tied to a recorded source revision or content hash, so its provenance is local and unpinned. Session transcript references are session-local. To make the evidence portable, the relevant outputs are excerpted below rather than relying on those references as the only record. Repository inputs were working-tree references and are therefore `integrity-unverified`.

The earlier sequential six-role smoke passed. That run did not test overlapping role execution and therefore did not establish concurrent safety or isolation.

## Six-role concurrent observation

The active-session task batch contained six standard roles; deep variants were excluded. The probes were issued as two calls per role, with A assigning a transient base-workspace marker and printing PID/time/owner, and B printing PID/time/owner plus a marker comparison. No role retried its failed or empty call. The root later removed the marker and observed `OMP_PARALLEL_CLEANUP_OK PID=52595`.

| Role | Call A | Call B | Directly supported result |
| --- | --- | --- | --- |
| `matlab-implementer` | `OMP_PARALLEL_A ROLE=matlab-implementer PID=52595 UTC=1792916174.358528 OWNER=matlab-implementer` | `OMP_PARALLEL_B ROLE=matlab-implementer PID=52595 UTC=1792916179.257393 OWNER=matlab-implementer MATCH=1` | Both calls reported PID 52595; B saw A's marker. |
| `simulink-implementer` | Printed `OMP_PARALLEL_A ROLE=simulink-implementer PID=52595 UTC=1792916169.289642 OWNER=simulink-implementer`, then `Unrecognized function or variable 'p'.` | `OMP_PARALLEL_B ROLE=simulink-implementer PID=52595 UTC=1792916173.128156 OWNER=technical-writer MATCH=0` | B saw the technical-writer marker, not this role's marker. A produced output and then an error. |
| `matlab-validator` | Printed its own line (`PID=52595`, `UTC=1792916167.970835`, owner `matlab-validator`) and also a `simulink-implementer` A line (`PID=52595`, `UTC=1792916169.289642`). | `Character vector is not terminated properly.` | A response contained another role's output; B returned no PID/owner comparison. |
| `technical-writer` | `OMP_PARALLEL_A ROLE=technical-writer PID=52595 UTC=1792916170.582582 OWNER=technical-writer` | Empty tool response | A reported PID 52595; B supplied no measurement or error text. |
| `matlab-architect` | `Line numbers may not exceed the last expression.` followed by MATLAB MCP evaluation stack output | `Character vector is not terminated properly.` | No measurement values from either call. |
| `technical-writer-validator` | `Line numbers may not exceed the last expression.` followed by MATLAB MCP evaluation stack output | `Line numbers may not exceed the last expression.` followed by MATLAB MCP evaluation stack output | No measurement values from either call. |

The measured PID 52595 matches the parent PID, and the returned output includes cross-role material. The implementer's B call observed its own marker; the Simulink implementer's B call observed the writer's marker (`MATCH=0`). These are direct evidence of shared process identity among measured calls and workspace/output contamination during this batch. The architect and writer-validator produced no PID measurements, so no PID claim is made for them. This finite observation does not establish that every invocation always shares a process, nor characterize all request scheduling.

In the tested single-session configuration, the OMP parent and its task agents used one shared MCP endpoint and MATLAB session. Setting `--matlab-session-mode=new` did not create a fresh MATLAB session for each task. This observation does not imply a universal connection-to-session mapping for other server configurations, including the explicit multi-session tools described below.

The exact internal cause of the line-number, parse, unrecognized-variable, or empty-response outcomes is not established. The printed outputs, common PID, and observed marker mismatch establish contamination; they do not prove which layer caused each individual error. There were no retries that could mask or overwrite the original outcomes.

## Two MCP processes from the same executable

The root launched two MATLAB MCP server processes from the same installed executable path, `/Users/julio/Library/Application Support/MathWorks/Agentic Toolkits/v1/bin/matlab-mcp-server`. Both reported MATLAB MCP Server v0.15.0, exposed 14 tools, and included `model_read`. The server process IDs were 54779 (A) and 54780 (B).

Each instance's warm-up call reported a different MATLAB process and the same MATLAB root:

| Instance | Warm-up output |
| --- | --- |
| A | `INSTANCE_WARM LABEL=A PID=54940 ROOT=/Applications/MATLAB_R2026a.app` |
| B | `INSTANCE_WARM LABEL=B PID=54941 ROOT=/Applications/MATLAB_R2026a.app` |

Both instances were active concurrently: the reported A interval was 1792916543.512138–1792916546.526609, and B's returned interval was 1792916543.512187–1792916546.526515. The calls therefore overlapped in time and reported distinct MATLAB PIDs. However, the B worker's recovered local label and outgoing code used `LABEL=B`, assigned owner `B`, and asserted its own label/owner; its returned response instead contained A's label and owner:

| Instance | Returned probe output |
| --- | --- |
| A | `INSTANCE_BEGIN LABEL=A PID=54940 UTC=1792916543.512138`; `INSTANCE_END LABEL=A PID=54940 UTC=1792916546.526609 OWNER=A MATCH=1` |
| B | `INSTANCE_BEGIN LABEL=A PID=54941 UTC=1792916543.512187`; `INSTANCE_END LABEL=A PID=54941 UTC=1792916546.526515 OWNER=A MATCH=1` |

The B harness assertion correctly detected that the observed response did not match B's actual outgoing probe. This is cross-process request/output identity contamination despite distinct MATLAB PIDs and overlapping execution; it is not evidence that B intentionally ran A's request. Distinct PIDs establish separate MATLAB processes, but B's wrong-identity result prevents this probe from establishing independent or shared workspace state. The root recovered B's outgoing source from the exception traceback and confirmed the server terminated. Local `mcpEval.m` sets fixed request and editor identifiers and `fullFilePath`; this source observation does not prove that these identifiers caused the returned identity mismatch.

The root then repeated the probe with separate `--initial-working-folder` values. This did not correct the identity mismatch: server PIDs 55731 (A) and 55732 (B) reported MATLAB PIDs 55899 (A) and 55898 (B), respectively, and both exposed 14 tools including `model_read`. Each process reported its own configured folder, but both warm-up and overlapping probe responses used `LABEL=A` despite B's outgoing request using `LABEL=B`. The reported intervals were A `1792916662.590561–1792916665.603384` and B `1792916662.587009–1792916665.599102`, which overlap. Thus, distinct working folders were insufficient to resolve the request/output identity contamination in that run.

### Distinct executable copies with distinct working folders

The root then ran one bounded trial using two byte-identical copies of the server executable at distinct temporary paths:

| Attribute | Instance A | Instance B |
| --- | --- | --- |
| Executable | `.../omp-mcp-copy-probe-876gdpup/A/matlab-mcp-server` | `.../omp-mcp-copy-probe-876gdpup/B/matlab-mcp-server` |
| SHA-256 | `e1198d344a48393bb35d11993065190a3a883f8f1957a8576b9bba8b8adf0548` | `e1198d344a48393bb35d11993065190a3a883f8f1957a8576b9bba8b8adf0548` |
| MCP PID | `56546` | `56545` |
| MATLAB PID | `56700` | `56696` |
| Tool surface | 14 tools, including `model_read` | 14 tools, including `model_read` |
| Warm-up identity / folder | A identity and A folder reported correctly | B identity and B folder reported correctly |
| Overlapping probe | `BEGIN 1792916775.259152`; `END 1792916778.272568 OWNER=A MATCH=1` | `BEGIN 1792916775.241192`; `END 1792916778.254869 OWNER=B MATCH=1` |

Both probes returned the requested role identity and owner, passed their own assertions, and overlapped by about 2.996 s. The root cleared each process's marker, terminated both servers, and removed the temporary executable copies and folders through context cleanup. No persistent configuration or routing was changed.

The copied executables used the same MATLAB root, new-session and `-nodesktop` settings, and Simulink extension flags; only executable path and initial working folder differed. Cleanup removed both temporary copies and their folders after each process marker was cleared and each server terminated.

For this one tested setup, distinct executable paths together with distinct initial working folders allowed correct concurrent evaluation where two processes using the same executable path had returned A-identified output to B, including when their working folders differed. This is evidence that executable-path separation can allow correct concurrent calls in the bounded setup; it is not a production guarantee or evidence that separate process IDs alone suffice. The local MATLAB session factory creates a `matlab-session-` subdirectory; this does not establish the mechanism linking executable path to the observed result. No cause is established. This single trial does not establish six-worker scaling, Simulink model parallelism, license or memory safety, or general concurrency correctness.

## Relevant MATLAB MCP configuration path

The inspected installed configurator's `GetToolsToAdd` checks `UseSingleMATLABSession()`. When true, it returns the single-session tools plus loaded custom tools; when false, it returns only the configured multi-session tools (`configurator.go:102-121`). The installed default parameter marks `use-single-matlab-session` hidden, names an environment variable, and sets its default to `true` (`defaultparameters.go:145-155`). Thus, disabling single-session mode changes the selected tool set and enables session-ID tools; it is not demonstrated to be a drop-in concurrency switch. In particular, the inspected false branch returns `multiSessionTools` without the Simulink extension tools added by the true branch's `loadCustomTools` path. These statements describe the inspected local source, not a revision-pinned release contract.

No configuration was changed, no runtime patched, and no recommendation to change this setting is an approved decision.

## Pilot implications and limits

For the pilot, stateful simulator/tool identity belongs in bounded task contracts when it affects correctness. Shared MATLAB state can expose or overwrite workspace variables; broader mutable context such as model selection, current directory/search path, and persistent state may also affect outcomes and needs deliberate ownership when tasks execute concurrently. Output that interleaves roles can compromise report attribution. Independent validation should not silently use the same mutable execution context as the implementation it is intended to validate.

These are operational implications of the observed collision, not evidence that every listed MATLAB state surface leaked in this run. This note does not broaden the result into product numerical, model-correctness, hardware, or MATLAB parallel-computing evidence.

## Bounded reproduction

Use only disposable scratch MATLAB MCP instances and workspaces. Do not call an existing user MATLAB session, open model, product workspace, or shared project session. Do not change persistent configuration. The two-call probe below is designed to expose request/response identity mix-ups as well as workspace-marker behavior; it does not test MATLAB Parallel Computing Toolbox or product execution.

1. Start two MCP server processes and connect a client to each through two fresh MCP connections. For both servers use the same installed MATLAB root and extension manifest, with these launch options: `--matlab-root=/Applications/MATLAB_R2026a.app`, `--matlab-session-mode=new`, `--matlab-display-mode=nodesktop`, `--extension-file="/Users/julio/Library/Application Support/MathWorks/Agentic Toolkits/v1/toolkits/simulink-agentic-toolkit/tools/tools.json"`, and `--disable-telemetry`. Set `--initial-working-folder` to a separate scratch folder for each instance; for the same-folder control, use the same scratch folder for both. First launch both processes from the same executable path; repeat with distinct initial folders; then copy the same executable to distinct temporary paths and use distinct temporary initial folders. Verify the copies are byte-identical by comparing SHA-256. Record MATLAB MCP version, tool inventory, executable hash, MCP process PID, MATLAB PID, complete launch arguments, exact request code, and exact response. Do not assume that separate MCP connections or MATLAB PIDs guarantee correct call attribution.
2. Submit call A and call B as separate `evaluate_matlab_code` requests through their respective fresh MCP connections, released together (or behind a client-side start barrier) so each request pauses for three seconds while the other runs. Each request writes a different owner marker in its own base workspace:

   **Request sent through connection A:**

   ```matlab
   assignin('base','omp_isolation_scratch_owner','A');
   fprintf('PROBE_BEGIN EXPECTED=A LABEL=A PID=%d UTC=%.6f OWNER=%s\n', ...
       matlabProcessID, posixtime(datetime('now','TimeZone','UTC')), ...
       evalin('base','omp_isolation_scratch_owner'));
   pause(3);
   fprintf('PROBE_END EXPECTED=A LABEL=A PID=%d UTC=%.6f OWNER=%s MATCH=%d\n', ...
       matlabProcessID, posixtime(datetime('now','TimeZone','UTC')), ...
       evalin('base','omp_isolation_scratch_owner'), ...
       strcmp(evalin('base','omp_isolation_scratch_owner'),'A'));
   ```

   **Request sent through connection B:**

   ```matlab
   assignin('base','omp_isolation_scratch_owner','B');
   fprintf('PROBE_BEGIN EXPECTED=B LABEL=B PID=%d UTC=%.6f OWNER=%s\n', ...
       matlabProcessID, posixtime(datetime('now','TimeZone','UTC')), ...
       evalin('base','omp_isolation_scratch_owner'));
   pause(3);
   fprintf('PROBE_END EXPECTED=B LABEL=B PID=%d UTC=%.6f OWNER=%s MATCH=%d\n', ...
       matlabProcessID, posixtime(datetime('now','TimeZone','UTC')), ...
       evalin('base','omp_isolation_scratch_owner'), ...
       strcmp(evalin('base','omp_isolation_scratch_owner'),'B'));
   ```

3. Preserve the sent request and returned response for each connection separately. Assert at the client/harness boundary that A's response contains `LABEL=A` and `OWNER=A`, and B's contains `LABEL=B` and `OWNER=B`; a response containing the other call's label is a failure even if its MATLAB PID is distinct. Record the begin/end UTC intervals and determine whether calls overlapped. A missing marker or execution error is evidence to report, not a reason to retry. Do not use a sequential “A writes, B reads” probe as a substitute for these simultaneous distinct-request checks.
4. Compare all three launch conditions: same executable/same initial folder, same executable/distinct initial folders, and byte-identical executable copies at distinct paths/distinct initial folders. Keep all other launch flags and environment settings constant. Interpret per-condition results; successful copies in one bounded trial do not certify general concurrent safety.
5. Clear only the scratch marker/session and temporary copies/folders created for this test, terminate the test servers, and record cleanup. Do not change persistent configuration or reuse any existing MATLAB session.

## Sources

- OMP v18.12.6 source: [`createMCPProxyTools`](https://github.com/can1357/oh-my-pi/blob/v18.12.6/packages/coding-agent/src/task/executor.ts#L960-L980) and task `mcpManager` option propagation ([selection](https://github.com/can1357/oh-my-pi/blob/v18.12.6/packages/coding-agent/src/task/executor.ts#L4570-L4572), [subagent options](https://github.com/can1357/oh-my-pi/blob/v18.12.6/packages/coding-agent/src/task/executor.ts#L4670-L4672)).
- Installed MATLAB MCP source (local, revision/hash not recorded): `internal/adaptors/mcp/server/configurator/configurator.go:102-121`, `internal/adaptors/application/parameter/defaultparameters/defaultparameters.go:145-155`, and `internal/adaptors/matlabmanager/matlabservices/services/localmatlabsession/directory/factory.go:78-85`. The local factory creates a session subdirectory, but this does not prove why separate executable paths changed the bounded probe result.
- Six-role runtime outputs: excerpts above from the active-session task results; parent cleanup observation `OMP_PARALLEL_CLEANUP_OK PID=52595`. These session outputs were not independently archived as a portable raw transcript.
- Same-executable, distinct-working-folder, and copied-executable MCP experiments: root-provided observations and recovered outgoing-code details relayed in the active session; exact identifiers, intervals, hashes, and output-identity results are transcribed above. The first experiment's tool output excerpt is preserved in `artifact://106`, a session-local artifact rather than a portable raw transcript. Installed `mcpEval.m:35-48` assigns fixed request/editor IDs and `fullFilePath`; this local source is revision/hash-unpinned and does not establish the error mechanism.
