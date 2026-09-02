"""验证 agent/src 目录布局可以作为唯一后端包加载。"""

from __future__ import annotations

import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[2]
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from agent.src.app import app


def main() -> None:
    assert app.title == "FOREMAN Course Backend"
    print("package layout verification passed")


if __name__ == "__main__":
    main()
