Md-ReadI - Getting Started Guide
================================

> Operational deployment blueprint for the Md-ReadI formatting engine.

&nbsp;

This document establishes the official technical onboarding instructions to integrate
the Md-ReadI formatting standard into your development workflow. The target objective
is to empower authors and automated agents to enforce the specification with near-zero
manual overhead.

By deploying the lightweight `package.sh` script, developers can choose between local
workspace automation, team-wide Git enforcement, or centralized pipeline validation.




&nbsp;
________________________________________________________________________________

## 1. ADOPTION STRATEGIES

The core formatting mechanics have been decoupled from individual projects, allowing
engineers to implement the standard under three distinct architectural topologies.



&nbsp;
---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- 

### 1.1 Global System Installation (XDG Baseline)

The global installation strategy is highly recommended for individual engineers who
want the formatting engine active across all markdown assets on their machine.

To install the utility globally following the standard XDG directory structure, execute
the following sequence inside your terminal session to fetch the script and grant
execution permissions:

``` bash
mkdir -p ~/.local/bin
curl -sSL https://raw.githubusercontent.com/AeonDigital/MD-ReadI/refs/heads/main/package.sh -o ~/.local/bin/md_readi.sh
chmod +x ~/.local/bin/md_readi.sh
```

Once installed, ensure `~/.local/bin` is included in your system's `$PATH` variable
to call the command globally from any directory block.



&nbsp;
---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- 

### 1.2 Local Project Integration (Git Hooks Approach)

The local integration strategy is ideal for development teams who want to guarantee
strict document compliance locally before any code changes are committed.

To bind the formatter directly to the repository lifecycle, save the script inside
a central utility folder and initialize a standard Git Pre-Commit hook sequence:

``` bash
mkdir -p .github/scripts
curl -sSL https://githubusercontent.com -o .github/scripts/md_readi.sh
chmod +x .github/scripts/md_readi.sh
```

Next, configure your local `.git/hooks/pre-commit` file to trigger the engine automatically
upon execution:

``` bash
#!/bin/sh
# Execute the formatter script across all staged markdown files
.github/scripts/md_readi.sh --staged
```



&nbsp;
---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- 

### 1.3 Centralized CI/CD Enforcement (GitHub Actions Pipeline)

The centralized pipeline strategy acts as an absolute verification line, blocking
malformed markdown documentation from entering production or main branches.

To integrate the tool into GitHub Actions, create a dedicated workflow file located
at `.github/workflows/md-readi-lint.yml`. This step allows teams to choose between
checking for bleeding-edge updates or locking the execution behavior to a specific
static tag version:

``` yaml
name: Md-ReadI Documentation Lint

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

      - name: Fetch and Execute Locked Format Checker
        run: |
          curl -sSL https://raw.githubusercontent.com/AeonDigital/MD-ReadI/refs/heads/main/package.sh -o md_readi.sh
          chmod +x md_readi.sh
          ./md_readi.sh --check
```




&nbsp;
________________________________________________________________________________

## 2. IDE AUTOMATION (VS CODE INTEGRATION)

To achieve maximum efficiency without installing third-party formatting extensions,
developers can leverage native VS Code configurations and environment pipelines.



&nbsp;
---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- 

### 2.1 Editor Real-Time Automation via Native Tasks

Because Md-ReadI relies entirely on the native shell environment, you can instruct
VS Code to invoke your global or local script file utilizing its built-in task runner.

Create or edit your local project directory configuration block located exactly at
`.vscode/tasks.json` and append the following automated task sequence:

``` json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Md-ReadI Auto-Format",
      "type": "shell",
      "command": "md_readi.sh",
      "args": ["${file}"],
      "presentation": {
        "reveal": "silent",
        "panel": "shared"
      },
      "runOptions": {
        "runOn": "folderOpen"
      }
    }
  ]
}
```



This structural configuration ensures the system environment execution layer remains
completely native, avoiding the requirement of external language extensions or plugins.



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