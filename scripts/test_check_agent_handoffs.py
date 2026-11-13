"""Tests for the agent handoff repository checker."""

from __future__ import annotations

import importlib.util
import shutil
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).with_name("check_agent_handoffs.py")
SPEC = importlib.util.spec_from_file_location("check_agent_handoffs", SCRIPT)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError(f"cannot load {SCRIPT}")
CHECKER = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = CHECKER
SPEC.loader.exec_module(CHECKER)


class AgentHandoffCheckTest(unittest.TestCase):
    """Exercise the checker at its repository-consumer boundary."""

    def _fixture(self) -> Path:
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        root = Path(temporary.name)
        shutil.copy2(CHECKER.ROOT / "AGENTS.md", root / "AGENTS.md")
        agents = root / ".omp/agents"
        agents.mkdir(parents=True)
        for name in CHECKER.NATIVE_ROLES:
            shutil.copy2(
                CHECKER.ROOT / ".omp/agents" / f"{name}.md",
                agents / f"{name}.md",
            )
        skill = root / ".agents/skills/diagrammer"
        skill.mkdir(parents=True)
        shutil.copy2(
            CHECKER.ROOT / ".agents/skills/diagrammer/SKILL.md",
            skill / "SKILL.md",
        )
        return root

    def _check(self, root: Path, name: str):
        return next(
            check
            for check in CHECKER.collect_checks(root, skip_markdownlint=True)
            if check.name == name
        )

    @staticmethod
    def _replace_frontmatter(content: str, field: str, value: str) -> str:
        prefix = f"{field}:"
        lines = content.splitlines()
        for index, line in enumerate(lines):
            if line.startswith(prefix):
                lines[index] = f"{prefix} {value}"
                return "\n".join(lines) + "\n"
        raise AssertionError(f"frontmatter field {field!r} is missing")

    def test_registry_parser_reads_only_specialist_table(self) -> None:
        contract = """\
## Specialist registry and conditional routing
| Agent | Route when the task is... |
| --- | --- |
| `writer` | Documentation |
| `validator` | Validation |

### OMP execution settings
| Roles | OMP default model selector | Thinking level |
| --- | --- | --- |
| `technical-writer` | `openai-codex/gpt-6-luna` | `high` |
| `matlab-implementer` | `openai-codex/gpt-6-luna` | `xhigh` |
| `matlab-architect` | `openai-codex/gpt-5.6-sol` | `high` |
| `technical-writer-validator`, `matlab-validator` | `model` | `medium` |
| `simulink-implementer` | `openai-codex/gpt-6.1-sol` | `medium` |

## Workflow sequencing
| `not-a-role` | ignored |
"""
        self.assertEqual(CHECKER._registry_names(contract), ["writer", "validator"])

    def test_packet_parser_reads_only_top_level_fields(self) -> None:
        contract = """\
```yaml
task:
  id: "one"
  checks:
    - name: "nested"
```
"""
        self.assertEqual(CHECKER._packet_fields(contract, "task"), {"id", "checks"})

    def test_omp_frontmatter_parses_repository_subset(self) -> None:
        agent = CHECKER._parse_omp_agent(
            '---\nname: "writer"\nspawns: ""\ntools: ["read"]\n---\nBody\n'
        )
        self.assertEqual(agent["name"], "writer")
        self.assertEqual(agent["spawns"], "")
        self.assertEqual(agent["tools"], ["read"])
        self.assertIn("Body", agent["_body"])

    def test_omp_frontmatter_rejects_malformed_or_duplicate_fields(self) -> None:
        for content in (
            'name: "writer"\n',
            '---\nname: "writer"\n',
            '---\nname: "writer"\nname: "other"\n---\n',
            "---\nname: writer\n---\n",
        ):
            with self.subTest(content=content), self.assertRaises(ValueError):
                CHECKER._parse_omp_agent(content)

    def test_checker_accepts_exact_six_native_roles(self) -> None:
        root = self._fixture()
        for name in (
            "specialist registry",
            "OMP native agents",
            "packet contract",
            "flat orchestration",
            "diagrammer boundary",
        ):
            with self.subTest(check=name):
                self.assertEqual(self._check(root, name).status, "passed")

    def test_diagrammer_remains_a_skill_not_a_specialist(self) -> None:
        root = self._fixture()
        diagrammer = root / ".omp/agents/diagrammer.md"
        diagrammer.write_text("unregistered specialist\n", encoding="utf-8")
        self.assertEqual(self._check(root, "diagrammer boundary").status, "failed")

    def test_native_inventory_rejects_missing_and_extra_deep_roles(self) -> None:
        with self.subTest(inventory="missing role"):
            root = self._fixture()
            (root / ".omp/agents/technical-writer-validator.md").unlink()
            self.assertEqual(self._check(root, "OMP native agents").status, "failed")
        with self.subTest(inventory="duplicate active role"):
            root = self._fixture()
            source = root / ".omp/agents/matlab-architect.md"
            (source.parent / "duplicate.md").write_text(
                source.read_text(encoding="utf-8"), encoding="utf-8"
            )
            self.assertEqual(self._check(root, "OMP native agents").status, "failed")
        with self.subTest(inventory="extra deep role"):
            root = self._fixture()
            source = root / ".omp/agents/matlab-architect.md"
            content = source.read_text(encoding="utf-8").replace(
                "matlab-architect", "matlab-architect-deep"
            )
            (source.parent / "matlab-architect-deep.md").write_text(
                content, encoding="utf-8"
            )
            self.assertEqual(self._check(root, "OMP native agents").status, "failed")

    def test_checker_rejects_duplicate_registry_role(self) -> None:
        root = self._fixture()
        path = root / "AGENTS.md"
        content = path.read_text(encoding="utf-8")
        content = content.replace(
            "| `matlab-validator` |",
            "| `matlab-architect` |",
            1,
        )
        path.write_text(content, encoding="utf-8")
        self.assertEqual(self._check(root, "specialist registry").status, "failed")

    def test_checker_rejects_maintained_codex_specialist_toml(self) -> None:
        root = self._fixture()
        codex_agents = root / ".codex/agents"
        codex_agents.mkdir(parents=True)
        (codex_agents / "matlab-architect.toml").write_text(
            'name = "matlab-architect"\n', encoding="utf-8"
        )
        check = self._check(root, "OMP native agents")
        self.assertEqual(check.status, "failed")
        self.assertIn("maintained Codex specialist", check.evidence)

    def test_checker_rejects_malformed_or_duplicate_native_frontmatter(self) -> None:
        for replacement in (
            'name: "matlab-architect"\nname: "other"',
            "name: matlab-architect",
        ):
            with self.subTest(replacement=replacement):
                root = self._fixture()
                path = root / ".omp/agents/matlab-architect.md"
                content = path.read_text(encoding="utf-8")
                content = content.replace(
                    'name: "matlab-architect"',
                    replacement,
                    1,
                )
                path.write_text(content, encoding="utf-8")
                self.assertEqual(
                    self._check(root, "OMP native agents").status, "failed"
                )

    def test_native_declarations_reject_default_and_scope_drift(self) -> None:
        mutations = (
            ("description", '"Changed responsibility"'),
            ("model", '"openai-codex/not-approved"'),
            ("thinking-level", '"low"'),
            ("spawns", '"*"'),
            ("tools", '["read"]'),
        )
        for field, value in mutations:
            with self.subTest(field=field):
                root = self._fixture()
                path = root / ".omp/agents/matlab-implementer.md"
                content = self._replace_frontmatter(
                    path.read_text(encoding="utf-8"), field, value
                )
                path.write_text(content, encoding="utf-8")
                self.assertEqual(
                    self._check(root, "OMP native agents").status, "failed"
                )
        root = self._fixture()
        path = root / ".omp/agents/matlab-implementer.md"
        content = path.read_text(encoding="utf-8").replace(
            "Implement approved MATLAB code changes",
            "Implement unapproved MATLAB code changes",
            1,
        )
        path.write_text(content, encoding="utf-8")
        self.assertEqual(self._check(root, "OMP native agents").status, "failed")

    def test_native_checker_preserves_safety_and_root_only_policy(self) -> None:
        root = self._fixture()
        path = root / ".omp/agents/matlab-validator.md"
        content = path.read_text(encoding="utf-8").replace(
            "This role is inspection-only.", "This role may edit.", 1
        )
        path.write_text(content, encoding="utf-8")
        self.assertEqual(self._check(root, "OMP native agents").status, "failed")

        root = self._fixture()
        path = root / ".omp/agents/matlab-implementer.md"
        content = path.read_text(encoding="utf-8")
        safeguard = "do not\nconfine filesystem or external-service access"
        self.assertIn(safeguard, content)
        self.assertEqual(self._check(root, "OMP native agents").status, "passed")

        root = self._fixture()
        path = root / ".omp/agents/matlab-implementer.md"
        content = path.read_text(encoding="utf-8")
        self.assertIn(safeguard, content)
        content = content.replace(
            safeguard,
            "confine filesystem or external-service access",
            1,
        )
        path.write_text(content, encoding="utf-8")
        self.assertEqual(self._check(root, "OMP native agents").status, "failed")

        root = self._fixture()
        path = root / ".omp/agents/matlab-architect.md"
        content = path.read_text(encoding="utf-8").replace(
            "do not spawn subagents", "delegate to subagents", 1
        )
        path.write_text(content, encoding="utf-8")
        self.assertEqual(self._check(root, "OMP native agents").status, "failed")

    def test_packet_contract_rejects_missing_field_or_status(self) -> None:
        for target in (
            "  allowed_mutations:\n"
            '    - "paths or external resources this agent may change"',
            '  status: "complete | needs-input | blocked | failed"',
        ):
            with self.subTest(target=target):
                root = self._fixture()
                path = root / "AGENTS.md"
                path.write_text(
                    path.read_text(encoding="utf-8").replace(target, "", 1),
                    encoding="utf-8",
                )
                self.assertEqual(self._check(root, "packet contract").status, "failed")

    def test_result_after_agent_metadata_excludes_sibling_fields(self) -> None:
        contract = """```yaml
agent:
  id: "agent"
  model: "model"
result:
  status: "complete"
  checks:
    - name: "nested"
other:
  unrelated: true
```"""
        self.assertEqual(
            CHECKER._packet_fields(contract, "result"), {"status", "checks"}
        )


if __name__ == "__main__":
    unittest.main()
