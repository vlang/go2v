# AGENTS Guide for py2v — concise rules for automated agents

Purpose
- Short, actionable rules for automated agents working in this repository.

High level
- py2v is a two-stage transpiler: the Python frontend (`frontend/ast_dump.py`) emits
  an enriched JSON AST; the V backend (`parser.v` + `transpiler.v`) parses that JSON and
  generates V code. Make semantic/analysis changes in the Python frontend; make codegen
  and emission changes in the V backend.

Key files (read in this order)
- `frontend/ast_dump.py` — semantic passes and v_annotation hints.
- `ast.v` — canonical V AST types; keep in sync with parser output.
- `parser.v` — JSON → V AST conversion (update when frontend JSON changes).
- `transpiler.v` — core codegen, ordering, and module/main emission.
- `plugins.v` — builtin translations (use `dispatch_builtin()`).
- `types.v` — Python→V type mapping and identifier escaping.

Change workflow (required)
- If behavior depends on semantic context, implement it in `frontend/ast_dump.py` first.
- If frontend JSON shape changes, update `ast.v` and `parser.v` together.
- Then update `transpiler.v` and/or `plugins.v` and add a fixture pair under
  `tests/cases/<name>.py` and `tests/expected/<name>.v`.

Build & test (development)
- Build: from repo root run `v .` (do not use `-o` during normal development).
- Run regression suite: `sh tests/run_tests.sh` (Linux/macOS).
- Targeted V test: `v test py2v_test.v`.
- Refresh expected fixtures after intentional changes: `sh tests/update_expected.sh`.
- Reproduce a case quickly: `./py2v tests/cases/<case>.py`.
- Inspect frontend JSON only: `python3 frontend/ast_dump.py tests/cases/<case>.py`.

Mandatory guardrails (enforced for all agent work)
- Add `2>&1` to commands that may emit to stderr so all output is captured.
- Keep `.md` lines ≤ 100 characters and run `v check-md` on edited markdown.
- Use `//` for V doc comments — do NOT use `///` or `/**`.
- Do NOT run any git commands, create branches, PRs, or changelogs.
- Do NOT create repository-local temporary files; use subdirectories under `/tmp` or another
  out-of-repo location for any artifacts you must write.
- Avoid module-level mutable globals in repository source code; prefer struct fields
  (e.g., on `VTranspiler`) or explicit parameters.
- After edits, run `v -check` and `v vet` (target a file or `.`) and fix all `v vet`
  notices/warnings. Then run `v fmt -w .` on `.v` files.

Guidance highlights
- Implement builtin translations in `plugins.v::dispatch_builtin()` and call
  `t.add_using(...)` for required imports.
- Prefer adding semantic inference and annotations in the Python frontend so the V
  backend can generate simpler, deterministic code.
- Use `v vet` and `v -check` outputs captured to a safe temporary location
  (e.g., a subdirectory of `/tmp`) if you need to aggregate results — do not create temporary
  files inside the repository.

End of agent rules.
