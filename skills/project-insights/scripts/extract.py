#!/usr/bin/env python3
"""
Project Insights — Cross-session JSONL analyzer for Claude Code.

Parses Claude Code session JSONL files to extract patterns, friction hotspots,
and generate CLAUDE.md recommendations. Works with any project.

Usage:
    python3 extract.py --sessions-dir ~/.claude/projects/<mangled-path> --days 30 --top 10
"""

import argparse
import json
import os
import re
import sys
from collections import Counter, defaultdict
from datetime import datetime, timedelta, timezone
from pathlib import Path


def parse_args():
    parser = argparse.ArgumentParser(description="Project Insights analyzer")
    parser.add_argument(
        "--sessions-dir", required=True, help="Path to Claude Code sessions directory"
    )
    parser.add_argument(
        "--days", type=int, default=30, help="Analyze sessions from last N days (default: 30)"
    )
    parser.add_argument(
        "--top", type=int, default=10, help="Number of results per category (default: 10)"
    )
    return parser.parse_args()


def find_session_files(sessions_dir: str, days: int) -> list[Path]:
    """Find JSONL session files within the date range."""
    cutoff = datetime.now(timezone.utc) - timedelta(days=days)
    session_files = []

    sessions_path = Path(sessions_dir)
    if not sessions_path.exists():
        print(f"Error: Sessions directory not found: {sessions_dir}", file=sys.stderr)
        sys.exit(1)

    # Look for .jsonl files directly and in subdirectories
    patterns = ["*.jsonl", "**/*.jsonl"]
    seen = set()
    for pattern in patterns:
        for f in sessions_path.glob(pattern):
            if f in seen or not f.is_file():
                continue
            seen.add(f)
            mtime = datetime.fromtimestamp(f.stat().st_mtime, tz=timezone.utc)
            if mtime >= cutoff:
                session_files.append(f)

    session_files.sort(key=lambda f: f.stat().st_mtime, reverse=True)
    return session_files


def extract_tool_name(line_data: dict) -> str | None:
    """Extract tool name from a JSONL message line."""
    if isinstance(line_data, dict):
        # Check for tool_use content blocks
        content = line_data.get("content", [])
        if isinstance(content, list):
            for block in content:
                if isinstance(block, dict):
                    if block.get("type") == "tool_use":
                        return block.get("name")
        # Check for direct tool name
        if "tool" in line_data:
            return line_data["tool"]
        # Check message type
        msg_type = line_data.get("type", "")
        if msg_type == "tool_use":
            return line_data.get("name")
    return None


def extract_file_paths(line_data: dict) -> list[tuple[str, str]]:
    """Extract file paths and their operation (read/edit/write) from tool calls."""
    paths = []
    content = line_data.get("content", [])
    if not isinstance(content, list):
        return paths

    for block in content:
        if not isinstance(block, dict) or block.get("type") != "tool_use":
            continue

        name = block.get("name", "")
        inp = block.get("input", {})
        if not isinstance(inp, dict):
            continue

        if name == "Read" and "file_path" in inp:
            paths.append((inp["file_path"], "read"))
        elif name == "Edit" and "file_path" in inp:
            paths.append((inp["file_path"], "edit"))
        elif name == "Write" and "file_path" in inp:
            paths.append((inp["file_path"], "write"))
        elif name == "Glob" and "pattern" in inp:
            paths.append((inp["pattern"], "glob"))
        elif name == "Grep" and "pattern" in inp:
            path = inp.get("path", ".")
            paths.append((f"grep:{path}", "grep"))

    return paths


ERROR_PATTERNS = [
    re.compile(r"(?:Error|ERROR|error):\s*(.{10,80})", re.IGNORECASE),
    re.compile(r"(?:FAIL|FAILED|Failed)(?:ED)?:\s*(.{10,80})", re.IGNORECASE),
    re.compile(r"(?:Exception|exception):\s*(.{10,80})"),
    re.compile(r"(?:TypeError|ReferenceError|SyntaxError|RuntimeError):\s*(.{10,80})"),
    re.compile(r"(?:CS\d{4}|TS\d{4,5}):\s*(.{10,80})"),
    re.compile(r"(?:ENOENT|EACCES|ECONNREFUSED):\s*(.{10,60})"),
    re.compile(r"npm (?:ERR|WARN)!\s*(.{10,80})"),
    re.compile(r"(?:Build|Compilation)\s+(?:failed|error)", re.IGNORECASE),
]


def extract_errors(text: str) -> list[str]:
    """Extract error patterns from text content."""
    errors = []
    for pattern in ERROR_PATTERNS:
        for match in pattern.finditer(text):
            error_text = match.group(0).strip()[:120]
            errors.append(error_text)
    return errors


def get_text_content(line_data: dict) -> str:
    """Get all text content from a JSONL line for error scanning."""
    texts = []
    content = line_data.get("content", "")
    if isinstance(content, str):
        texts.append(content)
    elif isinstance(content, list):
        for block in content:
            if isinstance(block, dict):
                if block.get("type") == "text":
                    texts.append(block.get("text", ""))
                elif block.get("type") == "tool_result":
                    result_content = block.get("content", "")
                    if isinstance(result_content, str):
                        texts.append(result_content)
                    elif isinstance(result_content, list):
                        for sub in result_content:
                            if isinstance(sub, dict) and sub.get("type") == "text":
                                texts.append(sub.get("text", ""))
    return "\n".join(texts)


def extract_tokens(line_data: dict) -> int:
    """Extract token count from message metadata."""
    usage = line_data.get("usage", {})
    if isinstance(usage, dict):
        return (
            usage.get("input_tokens", 0)
            + usage.get("output_tokens", 0)
            + usage.get("cache_read_input_tokens", 0)
            + usage.get("cache_creation_input_tokens", 0)
        )
    return 0


def extract_branch(line_data: dict) -> str | None:
    """Try to extract git branch from message content."""
    text = get_text_content(line_data)
    branch_match = re.search(r"(?:branch|Branch):\s*(\S+)", text)
    if branch_match:
        return branch_match.group(1)
    return None


def process_session(filepath: Path) -> dict:
    """Process a single JSONL session file."""
    session_id = filepath.stem
    mtime = datetime.fromtimestamp(filepath.stat().st_mtime, tz=timezone.utc)

    result = {
        "session_id": session_id,
        "date": mtime.strftime("%Y-%m-%d"),
        "timestamp": mtime.isoformat(),
        "message_count": 0,
        "token_count": 0,
        "tools": Counter(),
        "tool_sequence": [],
        "errors": [],
        "files_read": Counter(),
        "files_edited": Counter(),
        "branch": None,
    }

    try:
        with open(filepath, "r", encoding="utf-8", errors="replace") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue

                try:
                    data = json.loads(line)
                except json.JSONDecodeError:
                    continue

                if not isinstance(data, dict):
                    continue

                result["message_count"] += 1
                result["token_count"] += extract_tokens(data)

                # Extract tool usage
                tool = extract_tool_name(data)
                if tool:
                    result["tools"][tool] += 1
                    result["tool_sequence"].append(tool)

                # Also check content blocks for multiple tools per message
                content = data.get("content", [])
                if isinstance(content, list):
                    for block in content:
                        if isinstance(block, dict) and block.get("type") == "tool_use":
                            t = block.get("name")
                            if t and t != tool:
                                result["tools"][t] += 1
                                result["tool_sequence"].append(t)

                # Extract file paths
                for path, op in extract_file_paths(data):
                    if op in ("read", "glob"):
                        result["files_read"][path] += 1
                    elif op in ("edit", "write"):
                        result["files_edited"][path] += 1

                # Extract errors
                text = get_text_content(data)
                if text:
                    for err in extract_errors(text):
                        result["errors"].append(err)

                # Extract branch
                if not result["branch"]:
                    branch = extract_branch(data)
                    if branch:
                        result["branch"] = branch

    except (OSError, PermissionError) as e:
        print(f"Warning: Could not read {filepath}: {e}", file=sys.stderr)

    return result


def compute_trigrams(tool_sequence: list[str]) -> list[tuple[str, ...]]:
    """Compute tool usage trigrams from a sequence."""
    if len(tool_sequence) < 3:
        return []
    return [
        (tool_sequence[i], tool_sequence[i + 1], tool_sequence[i + 2])
        for i in range(len(tool_sequence) - 2)
    ]


def normalize_error(error: str) -> str:
    """Normalize an error string for deduplication."""
    normalized = re.sub(r"/[\w/.-]+", "<path>", error)
    normalized = re.sub(r"line \d+", "line N", normalized)
    normalized = re.sub(r"\b\d{3,}\b", "N", normalized)
    normalized = re.sub(r"'[^']{20,}'", "'...'", normalized)
    return normalized.strip()


def detect_project_name(sessions_dir: str) -> str | None:
    """Try to extract project name from the sessions directory path."""
    # The mangled path looks like -Users-wuu-Desktop-project-name
    # Try to find the last meaningful segment
    parts = Path(sessions_dir).name.split("-")
    # Filter out common path segments
    skip = {"Users", "home", "Desktop", "Documents", "Projects", "PlayGround", "SideProjects", ""}
    meaningful = [p for p in parts if p not in skip]
    if meaningful:
        return "-".join(meaningful[-3:])  # Last 3 meaningful segments
    return None


def generate_recommendations(
    common_errors: list[dict],
    file_hotspots_edited: list[dict],
    recurring_errors: list[dict],
    top_n: int,
) -> list[dict]:
    """Generate CLAUDE.md recommendations based on patterns."""
    recommendations = []

    for err in recurring_errors[:top_n]:
        sessions = err["sessions"]
        if sessions >= 5:
            priority = "HIGH"
        elif sessions >= 3:
            priority = "MEDIUM"
        else:
            priority = "LOW"

        # Generic target — recommend root CLAUDE.md by default
        target = "CLAUDE.md"

        # Try to detect domain from error content
        pattern = err["pattern"].lower()
        if any(kw in pattern for kw in ["cs0", "cs1", "cs2", "dapper", "sqlexception", "dotnet", "build failed"]):
            target = "backend CLAUDE.md or .ai/tech-stack/"
        elif any(kw in pattern for kw in ["ts0", "ts1", "ts2", "vue", "nuxt", "vitest", "component", "jsx"]):
            target = "frontend CLAUDE.md or .ai/tech-stack/"
        elif any(kw in pattern for kw in ["sql", "procedure", "sp_", "mssql", "sqlcmd"]):
            target = "database CLAUDE.md or .ai/tech-stack/"
        elif any(kw in pattern for kw in ["playwright", "e2e", "selector", "locator", "timeout"]):
            target = "e2e CLAUDE.md or .ai/tech-stack/"

        recommendations.append({
            "priority": priority,
            "rule": f"Add rule to prevent: {err['pattern'][:100]}",
            "evidence": f"{err['sessions']} sessions, first seen {err['first_seen']}, last seen {err['last_seen']}",
            "target": target,
        })

    return recommendations


def analyze_sessions(session_files: list[Path], top_n: int, project_name: str | None) -> dict:
    """Analyze all session files and produce aggregate report."""
    total = len(session_files)
    all_sessions = []

    for i, filepath in enumerate(session_files):
        if (i + 1) % 10 == 0 or i == 0 or i == total - 1:
            print(f"Processing session {i + 1}/{total}...", file=sys.stderr)
        session = process_session(filepath)
        all_sessions.append(session)

    # Aggregate
    total_messages = sum(s["message_count"] for s in all_sessions)
    total_tokens = sum(s["token_count"] for s in all_sessions)

    # Tool usage
    tool_totals = Counter()
    all_trigrams = Counter()
    for s in all_sessions:
        tool_totals.update(s["tools"])
        for tri in compute_trigrams(s["tool_sequence"]):
            all_trigrams[tri] += 1

    total_tool_uses = sum(tool_totals.values()) or 1
    tool_usage = [
        {"tool": tool, "count": count, "pct": round(count / total_tool_uses * 100, 1)}
        for tool, count in tool_totals.most_common(top_n)
    ]
    top_trigrams = [
        {"sequence": list(tri), "count": count}
        for tri, count in all_trigrams.most_common(top_n)
    ]

    # File hotspots — clean paths relative to project
    read_totals = Counter()
    edit_totals = Counter()
    for s in all_sessions:
        read_totals.update(s["files_read"])
        edit_totals.update(s["files_edited"])

    def clean_path(p: str) -> str:
        """Strip absolute path prefix, keeping project-relative path."""
        # Find common project directory markers
        for marker in ["/src/", "/lib/", "/app/", "/pages/", "/components/",
                       "/services/", "/tests/", "/test/", "/spec/"]:
            idx = p.find(marker)
            if idx >= 0:
                # Walk back to find the project root segment
                before = p[:idx]
                last_slash = before.rfind("/")
                if last_slash >= 0:
                    return p[last_slash + 1:]
        # Fallback: just use basename segments
        parts = p.split("/")
        if len(parts) > 3:
            return "/".join(parts[-3:])
        return p

    most_read = [
        {"path": clean_path(path), "count": count}
        for path, count in read_totals.most_common(top_n * 2)
        if not path.startswith("grep:")
    ][:top_n]

    most_edited = [
        {"path": clean_path(path), "count": count}
        for path, count in edit_totals.most_common(top_n)
    ][:top_n]

    # Error analysis
    all_errors = Counter()
    error_by_session = defaultdict(set)
    error_first_seen = {}
    error_last_seen = {}

    for s in all_sessions:
        session_errors = set()
        for err in s["errors"]:
            normalized = normalize_error(err)
            all_errors[normalized] += 1
            session_errors.add(normalized)

        for err in session_errors:
            error_by_session[err].add(s["session_id"])
            if err not in error_first_seen or s["date"] < error_first_seen[err]:
                error_first_seen[err] = s["date"]
            if err not in error_last_seen or s["date"] > error_last_seen[err]:
                error_last_seen[err] = s["date"]

    common_errors = [
        {"pattern": err, "count": count, "sessions": len(error_by_session[err])}
        for err, count in all_errors.most_common(top_n)
    ]

    # High-error sessions
    high_error_sessions = sorted(
        [s for s in all_sessions if len(s["errors"]) > 5],
        key=lambda s: len(s["errors"]),
        reverse=True,
    )[:top_n]
    high_error_list = [
        {
            "session": s["session_id"][:12],
            "date": s["date"],
            "error_count": len(s["errors"]),
            "top_errors": [normalize_error(e) for e in s["errors"][:3]],
        }
        for s in high_error_sessions
    ]

    # Recurring errors (2+ sessions)
    recurring = [
        {
            "pattern": err,
            "sessions": len(sessions),
            "first_seen": error_first_seen.get(err, "unknown"),
            "last_seen": error_last_seen.get(err, "unknown"),
        }
        for err, sessions in sorted(
            error_by_session.items(), key=lambda x: len(x[1]), reverse=True
        )
        if len(sessions) >= 2
    ][:top_n]

    # Recommendations
    recommendations = generate_recommendations(common_errors, most_edited, recurring, top_n)

    # Date range
    dates = [s["date"] for s in all_sessions if s["date"]]
    date_from = min(dates) if dates else "unknown"
    date_to = max(dates) if dates else "unknown"

    return {
        "meta": {
            "sessions_analyzed": total,
            "project": project_name or "unknown",
            "date_range": {"from": date_from, "to": date_to},
            "total_messages": total_messages,
            "total_tokens": total_tokens,
        },
        "friction": {
            "high_error_sessions": high_error_list,
            "common_errors": common_errors,
        },
        "tools": {
            "usage": tool_usage,
            "trigrams": top_trigrams,
        },
        "files": {
            "most_read": most_read,
            "most_edited": most_edited,
        },
        "repetitions": {
            "recurring_errors": recurring,
        },
        "recommendations": recommendations,
    }


def main():
    args = parse_args()

    print(f"Finding sessions in: {args.sessions_dir}", file=sys.stderr)
    print(f"Date range: last {args.days} days, top {args.top} results", file=sys.stderr)

    project_name = detect_project_name(args.sessions_dir)
    session_files = find_session_files(args.sessions_dir, args.days)

    if not session_files:
        print("No session files found in the specified date range.", file=sys.stderr)
        json.dump({"meta": {"sessions_analyzed": 0}, "error": "No sessions found"}, sys.stdout, indent=2)
        sys.exit(0)

    print(f"Found {len(session_files)} session files", file=sys.stderr)

    report = analyze_sessions(session_files, args.top, project_name)

    json.dump(report, sys.stdout, indent=2)
    print(file=sys.stdout)  # trailing newline

    print(f"\nDone. Analyzed {report['meta']['sessions_analyzed']} sessions.", file=sys.stderr)


if __name__ == "__main__":
    main()
