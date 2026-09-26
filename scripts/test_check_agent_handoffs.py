"""Tests for the agent handoff repository checker."""

from __future__ import annotations

import importlib.util
import sys
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

    def test_current_repository_contract_passes(self) -> None:
        checks = CHECKER.collect_checks(CHECKER.ROOT, skip_markdownlint=True)
        failures = [check for check in checks if check.status == "failed"]
        self.assertEqual(failures, [])

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
