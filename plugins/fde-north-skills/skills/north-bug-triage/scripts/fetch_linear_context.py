#!/usr/bin/env python3
"""Render a single consolidated Linear context Markdown file from JSON exports.

Output layout (top-heavy, high-signal first):

1. Metadata block
2. Artifact Index (title | url | source) — the canonical place for URL/artifact
   recognition; support-bundle detection scans this table.
3. Description (verbatim)
4. Comments (verbatim, chronological)
"""

import json
import re
import sys
from pathlib import Path


MARKDOWN_LINK_PATTERN = re.compile(r"!?\[([^\]]*)\]\((https?://[^)\s]+)\)")
PLAIN_URL_PATTERN = re.compile(r"https?://[^\s<>()\]]+")
COMMENT_SHORT_ID_PATTERN = re.compile(r"#comment-([A-Za-z0-9]+)")
TRAILING_PUNCT = ".,'\">"


def usage():
    print(
        "Usage: fetch_linear_context.py ISSUE_JSON COMMENTS_JSON CONTEXT_MD",
        file=sys.stderr,
    )


def get_nested(data, *keys):
    current = data
    for key in keys:
        if not isinstance(current, dict):
            return None
        current = current.get(key)
        if current is None:
            return None
    return current


def load_comments(comments_data):
    if isinstance(comments_data, dict):
        return comments_data.get("nodes", [])
    if isinstance(comments_data, list):
        return comments_data
    return []


def comment_short_id(comment):
    url = comment.get("url") or ""
    match = COMMENT_SHORT_ID_PATTERN.search(url)
    if match:
        return match.group(1)
    cid = comment.get("id") or ""
    return cid[:8] if cid else "unknown"


def extract_artifacts(text, source):
    """Return [{title, url, source}] for every markdown link and plain URL in text."""
    text = text or ""
    out = []
    markdown_spans = []

    for match in MARKDOWN_LINK_PATTERN.finditer(text):
        raw_title = (match.group(1) or "").strip()
        url = match.group(2).rstrip(TRAILING_PUNCT)
        title = raw_title or url
        out.append({"title": title, "url": url, "source": source})
        markdown_spans.append((match.start(2), match.end(2)))

    for match in PLAIN_URL_PATTERN.finditer(text):
        start = match.start()
        if any(span_start <= start < span_end for span_start, span_end in markdown_spans):
            continue
        url = match.group().rstrip(TRAILING_PUNCT)
        out.append({"title": url, "url": url, "source": source})

    return out


def dedupe_artifacts(artifacts):
    """Dedupe by URL, keeping the first occurrence so the strongest source wins."""
    seen = set()
    result = []
    for item in artifacts:
        url = item["url"]
        if not url or url in seen:
            continue
        seen.add(url)
        result.append(item)
    return result


def md_cell(text):
    """Escape pipe chars and newlines so a markdown table cell stays well-formed."""
    return (text or "").replace("|", "\\|").replace("\r", " ").replace("\n", " ")


def collect_labels(issue):
    labels = get_nested(issue, "labels", "nodes") or []
    return [node.get("name") for node in labels if node.get("name")]


def metadata_rows(issue):
    labels = collect_labels(issue)
    rows = [
        ("Title", issue.get("title")),
        ("URL", issue.get("url")),
        ("State", get_nested(issue, "state", "name")),
        ("Priority", issue.get("priorityLabel") or issue.get("priority")),
        (
            "Assignee",
            get_nested(issue, "assignee", "displayName")
            or get_nested(issue, "assignee", "name"),
        ),
        ("Team", get_nested(issue, "team", "key")),
        ("Project", get_nested(issue, "project", "name")),
        ("Cycle", get_nested(issue, "cycle", "name")),
        ("Milestone", get_nested(issue, "projectMilestone", "name")),
        ("Branch", issue.get("branchName")),
        ("Created", issue.get("createdAt")),
        ("Updated", issue.get("updatedAt")),
        ("Labels", ", ".join(labels) if labels else None),
    ]

    parent_identifier = get_nested(issue, "parent", "identifier")
    parent_title = get_nested(issue, "parent", "title")
    if parent_identifier or parent_title:
        parent_summary = parent_identifier or ""
        if parent_title:
            parent_summary = (
                f"{parent_summary}: {parent_title}" if parent_summary else parent_title
            )
        rows.append(("Parent", parent_summary))

    return rows


def render_metadata_block(issue, attachments, documents, comments):
    lines = ["## Metadata", ""]
    for label, value in metadata_rows(issue):
        if value not in (None, ""):
            lines.append(f"- {label}: {value}")
    lines.append(f"- Attachments: {len(attachments)}")
    lines.append(f"- Documents: {len(documents)}")
    lines.append(f"- Comments: {len(comments)}")
    lines.append("")
    return lines


def render_artifact_index(artifacts):
    lines = ["## Artifact Index", ""]
    if not artifacts:
        lines.append("- None")
        lines.append("")
        return lines

    lines.append("| Title / filename | URL | Source |")
    lines.append("|---|---|---|")
    for artifact in artifacts:
        lines.append(
            f"| {md_cell(artifact['title'])} "
            f"| {md_cell(artifact['url'])} "
            f"| {md_cell(artifact['source'])} |"
        )
    lines.append("")
    return lines


def render_description(description):
    lines = ["## Description", ""]
    if description:
        lines.append(description.rstrip())
    else:
        lines.append("(no description)")
    lines.append("")
    return lines


def render_comments_section(comments):
    lines = ["## Comments", ""]
    if not comments:
        lines.append("(no comments)")
        lines.append("")
        return lines

    for comment in comments:
        author = (
            get_nested(comment, "user", "displayName")
            or get_nested(comment, "user", "name")
            or "unknown"
        )
        created_at = comment.get("createdAt") or "unknown"
        comment_url = comment.get("url") or ""
        parent_id = get_nested(comment, "parent", "id")
        body = (comment.get("body") or "").rstrip()

        lines.append(f"### {created_at} — {author}")
        if comment_url:
            lines.append(f"- Comment URL: {comment_url}")
        if parent_id:
            lines.append(f"- Parent: {parent_id}")
        lines.append("")
        if body:
            lines.append(body)
        lines.append("")

    return lines


def build_artifacts(issue, description, comments):
    artifacts = []

    for item in get_nested(issue, "attachments", "nodes") or []:
        url = item.get("url") or ""
        if not url:
            continue
        title = item.get("title") or "untitled"
        artifacts.append({"title": title, "url": url, "source": "attachment"})

    for item in get_nested(issue, "documents", "nodes") or []:
        url = item.get("url") or ""
        if not url:
            continue
        title = item.get("title") or "untitled"
        artifacts.append({"title": title, "url": url, "source": "document"})

    artifacts.extend(extract_artifacts(description, "description"))

    for comment in comments:
        short_id = comment_short_id(comment)
        artifacts.extend(extract_artifacts(comment.get("body") or "", f"comment:{short_id}"))

    return dedupe_artifacts(artifacts)


def main():
    if len(sys.argv) != 4:
        usage()
        return 1

    issue_path, comments_path, context_path = [Path(value) for value in sys.argv[1:]]

    issue = json.loads(issue_path.read_text(encoding="utf-8"))
    comments_data = json.loads(comments_path.read_text(encoding="utf-8"))

    comments = sorted(
        load_comments(comments_data), key=lambda item: item.get("createdAt") or ""
    )
    attachments = get_nested(issue, "attachments", "nodes") or []
    documents = get_nested(issue, "documents", "nodes") or []
    description = issue.get("description") or ""

    artifacts = build_artifacts(issue, description, comments)

    lines = [f"# Linear Context: {issue.get('identifier') or 'unknown issue'}", ""]
    lines.extend(render_metadata_block(issue, attachments, documents, comments))
    lines.extend(render_artifact_index(artifacts))
    lines.extend(render_description(description))
    lines.extend(render_comments_section(comments))

    context_path.write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
