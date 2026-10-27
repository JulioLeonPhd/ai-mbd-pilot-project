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
    """Exercise parser behavior and the live repository contract."""

    def test_registry_parser_reads_only_specialist_table(self) -> None:
        contract = """\
## Specialist registry and conditional routing
| Agent | Route when the task is... |
| --- | --- |
| `writer` | Documentation |
| `validator` | Validation |
## Workflow sequencing
| `not-a-role` | ignored |
"""
        self.assertEqual(
            CHECKER._registry_names(contract),
            {"writer", "validator"},
        )

    def test_packet_parser_reads_top_level_fields(self) -> None:
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

    def test_omp_check_rejects_execution_policy_drift(self) -> None:
        agents, errors = CHECKER._load_agents(CHECKER.ROOT)
        self.assertEqual(errors, [])
        registry = {str(agent["name"]) for agent in agents}
        validator = next(
            agent for agent in agents if agent["name"] == "matlab-validator"
        )
        expected_model = CHECKER.OMP_MODELS[validator["model"]]
        mutations = (
            ('spawns: ""', 'spawns: "*"'),
            (
                f'model: "{expected_model}"',
                'model: "openai-codex/not-the-configured-model"',
            ),
            ('thinking-level: "medium"', 'thinking-level: "low"'),
            ('"web_search"]', '"web_search", "bash"]'),
        )
        for before, after in mutations:
            with self.subTest(before=before), tempfile.TemporaryDirectory() as temp:
                root = Path(temp)
                shutil.copytree(CHECKER.ROOT / ".omp/agents", root / ".omp/agents")
                path = root / ".omp/agents/matlab-validator.md"
                content = path.read_text(encoding="utf-8")
                self.assertIn(before, content)
                path.write_text(content.replace(before, after), encoding="utf-8")
                check = CHECKER._check_omp_agents(root, agents, registry)
                self.assertEqual(check.status, "failed")

    def test_omp_check_requires_every_registered_role(self) -> None:
        agents, errors = CHECKER._load_agents(CHECKER.ROOT)
        self.assertEqual(errors, [])
        registry = {str(agent["name"]) for agent in agents}
        with tempfile.TemporaryDirectory() as temp:
            check = CHECKER._check_omp_agents(Path(temp), agents, registry)
        self.assertEqual(check.status, "failed")

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
