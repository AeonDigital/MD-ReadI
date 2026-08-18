Md-ReadI - Getting Started Guide
================================

> Operational deployment blueprint for the Md-ReadI formatting engine.

&nbsp;

This document establishes the official technical onboarding instructions to integrate
the Md-ReadI formatting standard into your development workflow. The target objective
is to empower authors and automated agents to enforce the specification with near-zero
manual overhead.

The formatter is distributed as a standalone Bash script. It accepts a Markdown file
or a directory as its source and optionally writes formatted output to a separate
destination. It does not provide `--staged` or `--check` options: Git hooks and CI
must pass paths to the formatter and, for validation, compare the resulting changes.
The script requires Bash and standard Unix command-line utilities.




&nbsp;
________________________________________________________________________________

## 1. ADOPTION STRATEGIES

The core formatting mechanics have been decoupled from individual projects, allowing
engineers to implement the standard under three distinct architectural topologies.



&nbsp;
---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- 

### 1.1 Global System Installation

The global installation strategy is highly recommended for individual engineers who
want the formatting engine active across all markdown assets on their machine.

Download the package to `~/.local/bin/md_readi/package.sh` and grant it execution
permission:

``` bash
mkdir -p ~/.local/bin/md_readi
curl -fL https://raw.githubusercontent.com/AeonDigital/MD-ReadI/refs/heads/main/package.sh -o ~/.local/bin/md_readi/package.sh
chmod +x ~/.local/bin/md_readi/package.sh
```

Run the installed script by its path, for example `~/.local/bin/md_readi/package.sh
path/to/file.md` or `~/.local/bin/md_readi/package.sh path/to/docs`. Adding `~/.local/bin`
to `PATH` alone does not make the script available as `md_readi`, because the executable
is nested inside the `md_readi` directory. For a reproducible installation, replace
`main` in the URL with a release tag or commit reference.

To see the supported invocation syntax, run `~/.local/bin/md_readi/package.sh --help`.
The first argument is required and must be an existing `.md` file or directory. A
directory is searched recursively for lowercase `.md` files. With no second argument,
files are overwritten in place. With a second argument, a single source file requires
a file destination; a directory source requires a destination directory and preserves
the relative tree. The formatter is destructive when used in place, so commit or
back up work before running it.



&nbsp;
---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- 

### 1.2 Local Project Integration (Git Pre-Commit Hook)

Git hooks are local files and are not shared by cloning a repository. Install the
hook for each clone (or use a hook manager to provision it for the team). This example
uses Git's default hooks directory, `.git/hooks`; if `core.hooksPath` is configured,
set `hook_path` to the configured location instead. Resolving the default with `git
rev-parse --git-path` also works for linked worktrees, where `.git` is a file.

First download the formatter into the project and make it executable:

``` bash
mkdir -p .github/scripts
curl -fL https://raw.githubusercontent.com/AeonDigital/MD-ReadI/refs/heads/main/package.sh -o .github/scripts/md_readi.sh
chmod +x .github/scripts/md_readi.sh
```

Create Git's configured pre-commit hook with the following contents, then make the
hook itself executable. The hook finds staged Markdown files, formats each working-tree
file, and stages the formatted result:

``` bash
hook_path="$(git rev-parse --git-path hooks/pre-commit)"
mkdir -p "$(dirname "${hook_path}")"
cat > "${hook_path}" <<'EOF'
#!/usr/bin/env bash
set -e

root="$(git rev-parse --show-toplevel)"
formatter="${root}/.github/scripts/md_readi.sh"

while IFS= read -r -d '' file; do
  "${formatter}" "${root}/${file}"
  git -C "${root}" add -- "${file}"
done < <(git -C "${root}" diff --cached --name-only --diff-filter=ACMR -z -- '*.md')
EOF
chmod +x "${hook_path}"
```



The pre-commit hook formats the working-tree copy and re-stages the whole file. Review
the staged diff before committing, especially if the Markdown file also has unstaged
edits. Files not staged for the commit are not selected.



&nbsp;
---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- 

### 1.3 Centralized CI/CD Enforcement (GitHub Actions Pipeline)

The formatter has no read-only check mode. To validate formatting in CI, run it over
the checked-out Markdown files and fail if that changes tracked files.

Create `.github/workflows/md-readi-format.yml`. The example below tracks `main`;
pin the download URL to a release tag or commit if the workflow must use a fixed
version.

``` yaml
name: Md-ReadI Documentation Format

on:
  pull_request:
    paths:
      - '**/*.md'

jobs:
  lint-docs:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Repository Code
        uses: actions/checkout@v4

      - name: Format and Check Markdown
        run: |
          curl -fL https://raw.githubusercontent.com/AeonDigital/MD-ReadI/refs/heads/main/package.sh -o /tmp/md_readi
          chmod +x /tmp/md_readi
          /tmp/md_readi .
          git diff --exit-code -- '*.md'
```




The formatter rewrites files in the checkout; `git diff --exit-code` makes the job
fail when tracked Markdown files needed formatting. It does not automatically repair
a pull request.




&nbsp;
________________________________________________________________________________

## 2. IDE AUTOMATION (VS CODE INTEGRATION)

To achieve maximum efficiency without installing third-party formatting extensions,
developers can leverage native VS Code configurations and environment pipelines.



&nbsp;
---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- 

### 2.1 Run the Formatter from a VS Code Task

VS Code tasks can invoke the formatter for the currently open Markdown file. This
is a manually run task, not an on-save formatter. The example uses the project-local
installation from section 1.2; change the command to the installed path if preferred.

Create or edit `.vscode/tasks.json`:

``` json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Md-ReadI Format Current File",
      "type": "shell",
      "command": "${workspaceFolder}/.github/scripts/md_readi.sh",
      "args": ["${file}"],
      "problemMatcher": [],
      "presentation": {
        "reveal": "silent",
        "panel": "shared"
      }
    }
  ]
}
```



To use the global installation from section 1.1 instead, set `command` to `${env:HOME}/.local/bin/md_readi/package.sh`.

To run it: save the Markdown file, open the Command Palette (`Ctrl+Shift+P`), choose
**Tasks: Run Task** and select **Md-ReadI Format Current File**. The task formats
the active file in place and the editor reloads the new content (the task output
is hidden because of `"reveal": "silent"`). Only `.md` files are accepted; for any
other active file the task fails with an error. The task is not tied to the save
action, so run it again after each editing session. The same operation is available
in a terminal:

``` bash
.github/scripts/md_readi.sh docs/FILE.md
```

If nothing seems to change, confirm that the script is up to date and executable:
`<script> --help` must print the usage text. A script that exits silently without
formatting anything was built without the entry-point block and must be downloaded
again.



&nbsp;
---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- 

### 2.2 Visual Canvas Controls & Interactive Word-Wrapping

To provide an optimal real-time writing experience inside the editor canvas, authors
must establish strict visual boundaries to match the specification criteria.

Add the following properties to your configuration block to activate viewport constraints
and protect structural syntax layouts from destructive automated cleaning:

``` json
"[markdown]": {
    "files.trimTrailingWhitespace": false,
    "editor.wordWrap": "wordWrapColumn",
    "editor.wrappingIndent": "same",
    "editor.wordWrapColumn": 120
}
```


The strict inclusion of the `trimTrailingWhitespace` property set to `false` is mandatory
to prevent the editor from accidentally stripping intentional layout spacing keys.
Furthermore, developers can toggle interactive word-wrapping dynamically at any time
to evaluate text reflows by invoking the standard native keyboard shortcut sequence:

``` text
Windows/Linux: Alt + Z
macOS:         Option + Z
```




&nbsp;
________________________________________________________________________________

## 3. GOVERNANCE, EVOLUTION & DOMAIN EXTENSIONS

The criteria established across the Md-ReadI specification represent a continuous
effort to optimize human visual reading stamina and technical text processing.

&nbsp;

Because technical communication evolves alongside human learning and engineering
experience, this standard is explicitly treated as a living ecosystem. The maintainers
embrace an open policy regarding feedback, architectural revisions, and community-driven
optimization proposals.



&nbsp;
---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- 

### 3.1 Proposing Domain-Specific Layout Extensions

While the baseline specification covers standard markdown software engineering prose,
different technological fields carry specialized structural requirements.

Authors, researchers, and data teams are actively invited to submit formal Requests
for Comments (RFCs) to introduce domain-specific layout rules, including:

- **Data Science & Mathematics:** Geometrical structures for embedded LaTeX matrices.
- **Finance & Business:** Standardized grid formatting for financial ledger blocks.
- **Healthcare & Operations:** Secure layouts for specialized operational logs.

Every community proposal submitted for a new domain extension must prioritize algorithmic
predictability. The suggested layout rules must be explicitly designed to be parsed
and enforced by deterministic scripts, ensuring that formatting compliance never
depends on human cognitive effort.