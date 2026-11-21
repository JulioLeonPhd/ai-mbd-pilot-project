"""Validate the repository's agent handoff and flat-orchestration contract."""

from __future__ import annotations

import argparse
import json
import os
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
        "openai-codex/gpt-6.2-sol",
        "high",
        False,
        ("design", "interfaces", "Julio owns"),
    ),
    "matlab-implementer": (
        "Implement MATLAB code and simple localized Simulink edits; use "
        "simulink-implementer for substantive model changes.",
        "openai-codex/gpt-6.1-terra",
        "medium",
        True,
        ("approved MATLAB code changes", "localized Simulink edits", "Julio owns"),
    ),
    "simulink-implementer": (
        "Implement substantive Simulink topology, interface, configuration, or "
        "multi-step MCP model changes.",
        "openai-codex/gpt-6.2-sol",
        "medium",
        True,
        ("substantive Simulink topology", "approved architecture", "Julio owns"),
    ),
    "matlab-validator": (
        "Independently validate complex MATLAB and Simulink changes, including "
        "control, solver, numerical, safety, and code-generation risks.",
        "openai-codex/gpt-6.2-sol",
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
        "openai-codex/gpt-6.2-sol",
        "high",
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
_MERMAID_SKILL = ".agents/skills/drawing-mermaid-diagrams/SKILL.md"
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


def _changed_markdown_paths(root: Path, base: str) -> list[str]:
    if not base or base.startswith("-"):
        raise ValueError("Markdown base must be a Git revision, not an option")

    pathspecs = (":(icase)*.md", ":(icase)*.markdown")
    changed = subprocess.run(
        [
            "git",
            "diff",
            "--name-only",
            "--diff-filter=ACMRT",
            "-z",
            base,
            "--",
            *pathspecs,
        ],
        cwd=root,
        check=True,
        capture_output=True,
    )
    untracked = subprocess.run(
        ["git", "ls-files", "--others", "--exclude-standard", "-z", "--", *pathspecs],
        cwd=root,
        check=True,
        capture_output=True,
    )
    paths = set(os.fsdecode(changed.stdout + untracked.stdout).split("\0"))
    return sorted(path for path in paths if path and (root / path).is_file())


def _check_markdownlint(root: Path, base: str) -> Check:
    name = "Markdown lint"
    try:
        paths = _changed_markdown_paths(root, base)
    except subprocess.CalledProcessError as error:
        output = os.fsdecode(error.stderr).strip()
        return _failed(name, f"Git path discovery failed: {output or error}")
    except (OSError, ValueError) as error:
        return _failed(name, f"Git path discovery failed: {error}")
    if not paths:
        return _passed(name, "no changed Markdown files")

    executable = shutil.which("markdownlint-cli2")
    if executable is None:
        return Check(name, "unavailable", "command not found")
    # The CLI's colon prefix makes each Git path literal rather than a glob.
    result = subprocess.run(
        [executable, "--no-globs", *(f":{path}" for path in paths)],
        cwd=root,
        check=False,
        capture_output=True,
        text=True,
    )
    if result.returncode == 0:
        return _passed(name, f"checked {len(paths)} changed Markdown files")
    output = (result.stdout + result.stderr).strip()
    return _failed(name, output or "command failed")


def collect_checks(
    root: Path = ROOT, *, skip_markdownlint: bool = False, markdown_base: str = "HEAD"
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

    mermaid_skill_present = (root / _MERMAID_SKILL).is_file()
    forbidden_mermaid_paths = [
        path
        for path in (
            ".agents/skills/diagrammer/SKILL.md",
            ".omp/agents/diagrammer.md",
            ".omp/agents/drawing-mermaid-diagrams.md",
        )
        if (root / path).exists()
    ]
    if mermaid_skill_present and not forbidden_mermaid_paths:
        checks.append(
            _passed("Mermaid boundary", "new skill present; forbidden paths absent")
        )
    else:
        checks.append(
            _failed(
                "Mermaid boundary",
                f"{_MERMAID_SKILL} present={mermaid_skill_present}; "
                f"forbidden paths present={forbidden_mermaid_paths}",
            )
        )

    if skip_markdownlint:
        checks.append(Check("Markdown lint", "skipped", "disabled by command option"))
    else:
        checks.append(_check_markdownlint(root, markdown_base))
    return checks


def main(argv: list[str] | None = None) -> int:
    """Run checks and return nonzero for failed or unavailable required checks."""

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--skip-markdownlint",
        action="store_true",
        help="skip the external Markdown lint check",
    )
    parser.add_argument(
        "--markdown-base",
        default="HEAD",
        metavar="REVISION",
        help="compare working-tree Markdown against this Git revision (default: HEAD)",
    )
    args = parser.parse_args(argv)
    checks = collect_checks(
        skip_markdownlint=args.skip_markdownlint, markdown_base=args.markdown_base
    )
    for check in checks:
        print(f"{check.status.upper():11} {check.name}: {check.evidence}")
    return int(any(check.status in {"failed", "unavailable"} for check in checks))


if __name__ == "__main__":
    sys.exit(main())
