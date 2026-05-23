# Agent Preferences

- Strict project rule: never write or modify source code in this project. This repository is for the user to learn Zig by writing the code themselves.
- Strict project rule: code shown in assistant output must be limited to at most one line at a time.
- Strict project rule: provide explanations, debugging guidance, and conceptual direction only unless the user explicitly changes this rule.
- For this project, keep code-help responses very short, roughly 20% of a normal explanation unless the user explicitly asks for more detail.
- Prefer describing changes and pointing to files over pasting large code blocks.
- Always inspect the current relevant source/test file state before answering code questions; do not rely on memory or prior transcript context when the file may have changed.
- Never modify project files for the user; provide guidance only and avoid generating multi-line code unless explicitly requested.
