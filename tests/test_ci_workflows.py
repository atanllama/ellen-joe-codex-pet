from pathlib import Path

import pytest


ROOT = Path(__file__).parents[1]
WORKFLOWS = (
    ROOT / ".github" / "workflows" / "validate.yml",
    ROOT / ".github" / "workflows" / "release.yml",
)


def _setup_python_step(workflow: Path) -> str:
    lines = workflow.read_text(encoding="utf-8").splitlines()
    start = lines.index("      - uses: actions/setup-python@v7")
    end = next(
        (index for index in range(start + 1, len(lines)) if lines[index].startswith("      - ")),
        len(lines),
    )
    return "\n".join(lines[start:end])


@pytest.mark.parametrize("workflow", WORKFLOWS, ids=lambda path: path.name)
def test_setup_python_pip_cache_depends_on_requirements_dev(workflow: Path) -> None:
    step = _setup_python_step(workflow)
    assert "          cache: pip" in step
    assert "          cache-dependency-path: requirements-dev.txt" in step
