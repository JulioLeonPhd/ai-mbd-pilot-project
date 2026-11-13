"""Validate the repository's agent handoff and flat-orchestration contract."""

from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TASK_FIELDS = (
    "id",
    "objective",
    "context",
    "inputs",
    "constraints",
    "acceptance_criteria",
    "allowed_mutations",
    "requested_checks",
)
RESULT_FIELDS = (
    "status",
    "summary",
    "artifacts",
    "changes",
    "checks",
    "findings",
    "assumptions",
    "handoff",
)
RESULT_STATUSES = ("complete", "needs-input", "blocked", "failed")

NATIVE_ROLES = (
    "matlab-architect",
    "matlab-implementer",
    "simulink-implementer",
    "matlab-validator",
    "technical-writer",
    "technical-writer-validator",
)
NATIVE_DECLARATIONS = {
    "matlab-architect": (
        "Design MATLAB and Simulink solutions, including solver, timing, numerical, "
        "and code-generation concerns.",
        "openai-codex/gpt-5.6-sol",
        "high",
        False,
        ("design", "interfaces", "Julio owns"),
    ),
    "matlab-implementer": (
        "Implement MATLAB code and simple localized Simulink edits; use "
        "simulink-implementer for substantive model changes.",
        "openai-codex/gpt-6-luna",
        "xhigh",
        True,
        ("approved MATLAB code changes", "localized Simulink edits", "Julio owns"),
    ),
    "simulink-implementer": (
        "Implement substantive Simulink topology, interface, configuration, or "
        "multi-step MCP model changes.",
        "openai-codex/gpt-6.1-sol",
        "medium",
        True,
        ("substantive Simulink topology", "approved architecture", "Julio owns"),
    ),
    "matlab-validator": (
        "Independently validate complex MATLAB and Simulink changes, including "
        "control, solver, numerical, safety, and code-generation risks.",
        "openai-codex/gpt-5.6-sol",
        "medium",
        False,
        (
            "Independently validate",
            "without changing implementation artifacts",
            "findings",
        ),
    ),
    "technical-writer": (
        "Produce concise Markdown documents and manifest JSON files.",
        "openai-codex/gpt-6-luna",
        "high",
        True,
        ("Create or edit concise Markdown", "approved", "technical-writer-validator"),
    ),
    "technical-writer-validator": (
        "Independently validate complex Markdown, including safety guidance and "
        "intricate architecture documentation.",
        "openai-codex/gpt-5.6-sol",
        "medium",
        False,
        ("Independently validate complex Markdown", "do not silently", "findings"),
    ),
}
OMP_READ_TOOLS = {"read", "grep", "glob", "web_search"}
OMP_WRITE_TOOLS = OMP_READ_TOOLS | {"write", "edit", "bash", "eval"}
OMP_READ_POLICY_MARKERS = (
    "MCP, extension, and custom tools may still",
    "not filesystem or external-service isolation",
)
OMP_WRITE_POLICY_MARKERS = (
    "extension, and custom tools only within that same authorization",
    "do not confine filesystem or external-service access",
)
MARKDOWN_PATHS = (
    "AGENTS.md",
    "README.md",
    ".agents/skills/diagrammer/SKILL.md",
    "docs/adr/0001-root-agent-orchestrated-matlab-simulink-specialists.md",
    "docs/adr/0018-flatten-specialist-orchestration.md",
    "docs/adr/0028-permit-bounded-omp-native-orchestration-simplification.md",
    "docs/plans/agent-handoff-token-optimisation.md",
    "docs/plans/omp-native-orchestration-simplification.md",
    "docs/agents/task-guidance.md",
    "docs/architecture/agent-orchestration-runtime.md",
    "CHANGELOG.md",
    ".omp/agents/matlab-architect.md",
    ".omp/agents/matlab-implementer.md",
    ".omp/agents/simulink-implementer.md",
    ".omp/agents/matlab-validator.md",
    ".omp/agents/technical-writer.md",
    ".omp/agents/technical-writer-validator.md",
)
OMP_PROMPT_MARKERS = (
    "Read the repository root `AGENTS.md` before acting",
    "do not spawn subagents",
    "`allowed_mutations`",
    "`requested_checks`",
    "`agent.name`, `agent.model`, `agent.reasoning_effort`",
    "`result.status`",
    "`integrity-unverified`",
    "does not reproduce Codex's",
)


@dataclass(frozen=True)
class Check:
    """One deterministic repository check result."""

    name: str
    status: str
    evidence: str


def _passed(name: str, evidence: str) -> Check:
    return Check(name, "passed", evidence)


def _failed(name: str, evidence: str) -> Check:
    return Check(name, "failed", evidence)


def _registry_names(contract: str) -> list[str]:
    section = contract.split("## Specialist registry and conditional routing", 1)
    if len(section) != 2:
        return []
    table = re.search(r"(?m)^\|.*(?:\n\|.*)*", section[1])
    if table is None:
        return []
    return re.findall(r"^\| `([^`]+)` \|", table.group(), flags=re.MULTILINE)


def _packet_fields(contract: str, packet: str) -> set[str]:
    for block in re.findall(r"```yaml\n(.*?)\n```", contract, re.DOTALL):
        match = re.search(
            rf"^{re.escape(packet)}:\n(?P<body>(?:[ \t].*\n|\n)*)",
            block + "\n",
            re.MULTILINE,
        )
        if match is not None:
            return set(re.findall(r"^  ([a-z_]+):", match.group("body"), re.MULTILINE))
    return set()


def _parse_omp_agent(content: str) -> dict[str, object]:
    """Read the repository's JSON-valued YAML subset, not arbitrary OMP YAML."""

    lines = content.splitlines()
    if not lines or lines[0] != "---":
        raise ValueError("missing opening frontmatter delimiter")
    try:
        end = lines.index("---", 1)
    except ValueError as error:
        raise ValueError("missing closing frontmatter delimiter") from error
    data: dict[str, object] = {}
    for line in lines[1:end]:
        key, separator, value = line.partition(":")
        if not separator or not key or key in data:
            raise ValueError(f"invalid or duplicate frontmatter key: {line!r}")
        try:
            data[key] = json.loads(value)
        except json.JSONDecodeError as error:
            raise ValueError(f"{key}: expected a JSON-valued YAML field") from error
    data["_body"] = "\n".join(lines[end + 1 :])
    return data


def _check_omp_agents(root: Path, registry: list[str]) -> Check:
    """Check the six native roles and their declared controls, not isolation."""

    errors: list[str] = []
    paths = sorted((root / ".omp/agents").glob("*.md"))
    names: list[str] = []
    parsed: dict[str, tuple[Path, dict[str, object]]] = {}
    for path in paths:
        label = str(path.relative_to(root))
        try:
            agent = _parse_omp_agent(path.read_text(encoding="utf-8"))
        except (OSError, ValueError) as error:
            errors.append(f"{label}: {error}")
            continue
        name = agent.get("name")
        if not isinstance(name, str) or not name:
            errors.append(f"{label}: invalid name")
            continue
        names.append(name)
        if path.stem != name:
            errors.append(f"{label}: filename does not match {name!r}")
        if name in parsed:
            errors.append(f"duplicate OMP agent name: {name}")
            continue
        parsed[name] = (path, agent)

    duplicate_registry = sorted({name for name in registry if registry.count(name) > 1})
    if duplicate_registry:
        errors.append(f"duplicate registry roles: {duplicate_registry}")
    if set(registry) != set(NATIVE_ROLES) or len(registry) != len(NATIVE_ROLES):
        errors.append(f"registry roles={registry}; expected={list(NATIVE_ROLES)}")
    if set(names) != set(NATIVE_ROLES) or len(names) != len(NATIVE_ROLES):
        errors.append(f"OMP roles={names}; expected={list(NATIVE_ROLES)}")

    for path in sorted((root / ".codex/agents").glob("*.toml")):
        errors.append(
            f"maintained Codex specialist definition: {path.relative_to(root)}"
        )

    required = {"name", "description", "model", "thinking-level", "spawns", "tools"}
    for name, (path, agent) in parsed.items():
        label = str(path.relative_to(root))
        expected = NATIVE_DECLARATIONS.get(name)
        if expected is None:
            errors.append(f"{label}: unexpected OMP role {name!r}")
            continue
        description, model, effort, writable, scope_markers = expected
        for key, value in (
            ("name", name),
            ("description", description),
            ("model", model),
            ("thinking-level", effort),
            ("spawns", ""),
        ):
            if agent.get(key) != value:
                errors.append(f"{label}: incorrect {key}; expected {value!r}")
        missing = required - agent.keys()
        if missing:
            errors.append(f"{label}: missing {', '.join(sorted(missing))}")
        tools = agent.get("tools")
        expected_tools = OMP_WRITE_TOOLS if writable else OMP_READ_TOOLS
        if (
            not isinstance(tools, list)
            or not all(isinstance(tool, str) for tool in tools)
            or set(tools) != expected_tools
            or len(tools) != len(expected_tools)
        ):
            errors.append(f"{label}: incorrect built-in tool allowlist")
        body = str(agent.get("_body", ""))
        normalized_body = " ".join(body.split())
        if f"# {name}\n" not in body:
            errors.append(f"{label}: missing role heading")
        policy_markers = (
            OMP_WRITE_POLICY_MARKERS if writable else OMP_READ_POLICY_MARKERS
        )
        for marker in (*OMP_PROMPT_MARKERS, *policy_markers, *scope_markers):
            if not re.search(
                r"(?<!\w)" + re.escape(marker) + r"(?!\w)", normalized_body
            ):
                errors.append(f"{label}: missing operating boundary {marker!r}")
        for sentence in re.split(r"(?<=[.!?])\s+", normalized_body):
            if re.search(
                r"\b(?:spawn\w*|delegate\w*)\b",
                sentence,
                flags=re.IGNORECASE,
            ) and not re.search(
                r"\b(?:do not|don't|never|must not|cannot|no tool may be)\b",
                sentence,
                flags=re.IGNORECASE,
            ):
                errors.append(f"{label}: may not spawn or delegate subagents")
        if name in {"matlab-validator", "technical-writer-validator"}:
            if (
                "inspection-only" not in body
                or "Do not invoke mutation operations" not in body
            ):
                errors.append(f"{label}: validator must remain nonrepairing")

    if errors:
        return _failed("OMP native agents", "; ".join(errors))
    return _passed(
        "OMP native agents",
        f"{len(names)} native roles; declared tools/spawns only, not OS isolation",
    )


def collect_checks(
    root: Path = ROOT, *, skip_markdownlint: bool = False
) -> list[Check]:
    """Collect every handoff-contract check without mutating the repository."""

    checks: list[Check] = []
    contract_path = root / "AGENTS.md"
    if not contract_path.is_file():
        return [_failed("orchestration contract", "AGENTS.md is missing")]
    contract = contract_path.read_text(encoding="utf-8")

    registry = _registry_names(contract)
    registry_set = set(registry)
    if len(registry) == len(NATIVE_ROLES) and registry_set == set(NATIVE_ROLES):
        checks.append(
            _passed("specialist registry", "contains exactly six native roles")
        )
    else:
        duplicates = sorted({name for name in registry if registry.count(name) > 1})
        checks.append(
            _failed(
                "specialist registry",
                f"roles={registry}; duplicates={duplicates}; "
                f"expected={list(NATIVE_ROLES)}",
            )
        )

    checks.append(_check_omp_agents(root, registry))

    task_fields = _packet_fields(contract, "task")
    result_fields = _packet_fields(contract, "result")
    missing_task = sorted(set(TASK_FIELDS) - task_fields)
    missing_result = sorted(set(RESULT_FIELDS) - result_fields)
    missing_statuses = [status for status in RESULT_STATUSES if status not in contract]
    if missing_task or missing_result or missing_statuses:
        checks.append(
            _failed(
                "packet contract",
                f"missing task={missing_task}, result={missing_result}, "
                f"statuses={missing_statuses}",
            )
        )
    else:
        checks.append(
            _passed("packet contract", "required field names and status tokens found")
        )

    if "Specialists work independently and never spawn subagents." not in contract:
        checks.append(
            _failed("flat orchestration", "missing root-only spawning policy")
        )
    else:
        checks.append(
            _passed("flat orchestration", "contract declares root-only spawning")
        )

    diagram_skill = root / ".agents/skills/diagrammer/SKILL.md"
    diagram_agent = root / ".omp/agents/diagrammer.md"
    if diagram_skill.is_file() and not diagram_agent.exists():
        checks.append(
            _passed("diagrammer boundary", "skill present; specialist absent")
        )
    else:
        checks.append(
            _failed(
                "diagrammer boundary",
                f"skill={diagram_skill.is_file()}, specialist={diagram_agent.exists()}",
            )
        )

    if skip_markdownlint:
        checks.append(Check("Markdown lint", "skipped", "disabled by command option"))
    else:
        executable = shutil.which("markdownlint-cli2")
        if executable is None:
            checks.append(Check("Markdown lint", "unavailable", "command not found"))
        else:
            paths = [
                str(root / path) for path in MARKDOWN_PATHS if (root / path).is_file()
            ]
            result = subprocess.run(
                [executable, *paths],
                cwd=root,
                check=False,
                capture_output=True,
                text=True,
            )
            if result.returncode == 0:
                checks.append(_passed("Markdown lint", f"checked {len(paths)} files"))
            else:
                output = (result.stdout + result.stderr).strip()
                checks.append(_failed("Markdown lint", output or "command failed"))
    return checks


def main(argv: list[str] | None = None) -> int:
    """Run checks and return nonzero for failed or unavailable required checks."""

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--skip-markdownlint",
        action="store_true",
        help="skip the external Markdown lint check",
    )
    args = parser.parse_args(argv)
    checks = collect_checks(skip_markdownlint=args.skip_markdownlint)
    for check in checks:
        print(f"{check.status.upper():11} {check.name}: {check.evidence}")
    return int(any(check.status in {"failed", "unavailable"} for check in checks))


if __name__ == "__main__":
    sys.exit(main())
