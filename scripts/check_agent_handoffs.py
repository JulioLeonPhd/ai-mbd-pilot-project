"""Validate the repository's agent handoff and flat-orchestration contract."""

from __future__ import annotations

import argparse
import re
import shutil
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path

try:
    import tomllib
except ModuleNotFoundError:  # pragma: no cover - Python 3.10 compatibility path
    import tomli as tomllib  # type: ignore[import-not-found,no-redef]

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
GLOBAL_PROMPT_MARKERS = (
    "task and result packet contract",
    "inherit-full-conversation",
    "allowed_mutations",
    "do not spawn subagents",
)
MARKDOWN_PATHS = (
    "AGENTS.md",
    "README.md",
    ".agents/skills/diagrammer/SKILL.md",
    "docs/adr/0001-root-agent-orchestrated-matlab-simulink-specialists.md",
    "docs/adr/0018-flatten-specialist-orchestration.md",
    "docs/plans/agent-handoff-token-optimisation.md",
    "docs/architecture/agent-orchestration-runtime.md",
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


def _registry_names(contract: str) -> set[str]:
    section = contract.split("## Specialist registry and conditional routing", 1)
    if len(section) != 2:
        return set()
    table = section[1].split("## Workflow sequencing", 1)[0]
    return set(re.findall(r"^\| `([^`]+)` \|", table, flags=re.MULTILINE))


def _packet_fields(contract: str, packet: str) -> set[str]:
    match = re.search(
        rf"```yaml\n{packet}:\n(?P<body>.*?)\n```",
        contract,
        flags=re.DOTALL,
    )
    if match is None:
        return set()
    return set(re.findall(r"^  ([a-z_]+):", match.group("body"), re.MULTILINE))


def _load_agents(root: Path) -> tuple[list[dict[str, object]], list[str]]:
    agents: list[dict[str, object]] = []
    errors: list[str] = []
    for path in sorted((root / ".codex/agents").glob("*.toml")):
        try:
            data = tomllib.loads(path.read_text(encoding="utf-8"))
        except (OSError, tomllib.TOMLDecodeError) as error:
            errors.append(f"{path.relative_to(root)}: {error}")
            continue
        data["_path"] = path
        agents.append(data)
    return agents, errors


def collect_checks(
    root: Path = ROOT, *, skip_markdownlint: bool = False
) -> list[Check]:
    """Collect every handoff-contract check without mutating the repository."""

    checks: list[Check] = []
    contract_path = root / "AGENTS.md"
    if not contract_path.is_file():
        return [_failed("orchestration contract", "AGENTS.md is missing")]
    contract = contract_path.read_text(encoding="utf-8")

    agents, parse_errors = _load_agents(root)
    required = {
        "name",
        "description",
        "model",
        "model_reasoning_effort",
        "sandbox_mode",
        "developer_instructions",
    }
    structural_errors = list(parse_errors)
    names: list[str] = []
    for agent in agents:
        path = agent["_path"]
        assert isinstance(path, Path)
        missing = required - agent.keys()
        if missing:
            structural_errors.append(
                f"{path.relative_to(root)}: missing {', '.join(sorted(missing))}"
            )
        name = agent.get("name")
        if not isinstance(name, str):
            structural_errors.append(f"{path.relative_to(root)}: invalid name")
            continue
        names.append(name)
        if path.stem != name:
            structural_errors.append(
                f"{path.relative_to(root)}: filename does not match {name!r}"
            )
    duplicate_names = sorted({name for name in names if names.count(name) > 1})
    if duplicate_names:
        structural_errors.append(f"duplicate agent names: {', '.join(duplicate_names)}")
    if structural_errors:
        checks.append(_failed("agent TOMLs", "; ".join(structural_errors)))
    else:
        checks.append(_passed("agent TOMLs", f"parsed {len(agents)} unique roles"))

    registry = _registry_names(contract)
    inventory = set(names)
    if registry == inventory:
        checks.append(_passed("specialist registry", f"matches {len(inventory)} TOMLs"))
    else:
        checks.append(
            _failed(
                "specialist registry",
                f"contract-only={sorted(registry - inventory)}; "
                f"TOML-only={sorted(inventory - registry)}",
            )
        )

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

    nested = []
    duplicated = []
    for agent in agents:
        instructions = str(agent.get("developer_instructions", "")).lower()
        name = str(agent.get("name", "<unnamed>"))
        if "spawn_agent" in instructions or re.search(
            r"spawn\w*\s+(?:a\s+)?(?:sub)?agent", instructions
        ):
            nested.append(name)
        markers = [marker for marker in GLOBAL_PROMPT_MARKERS if marker in instructions]
        if markers:
            duplicated.append(f"{name}: {', '.join(markers)}")
    if (
        nested
        or "Specialists work independently and never spawn subagents." not in contract
    ):
        checks.append(_failed("flat orchestration", f"nested roles={nested}"))
    else:
        checks.append(
            _passed(
                "flat orchestration",
                "contract declares root-only spawning; TOMLs contain no spawn markers",
            )
        )
    if duplicated:
        checks.append(_failed("role prompt economy", "; ".join(duplicated)))
    else:
        checks.append(
            _passed("role prompt economy", "no global prompt markers in TOMLs")
        )

    diagram_skill = root / ".agents/skills/diagrammer/SKILL.md"
    diagram_agent = root / ".codex/agents/diagrammer.toml"
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
