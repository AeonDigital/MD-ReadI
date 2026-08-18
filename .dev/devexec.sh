#!/usr/bin/env bash

# devexec.sh - Dynamic development environment context loader and runtime orchestrator.
# 
# Description:
# - Recursively discovers and sources active library functions located inside a specified
#   directory tree directly into the running shell execution context.
# - Implements defensive filter exclusions to prevent loading unit testing structures
#   (*_test.sh) or initialization automation pathways (*_autoexec.sh).
# 
# Constraints & Logistics:
# - Operating Directory: Must be executed strictly from the project's root directory path.
# - Target Directory:    Defaults to 'src' if no argument is provided, but accepts a custom
#                        path as the first positional parameter ($1).
# - File Location:      Stored and maintained inside the localized '.dev/' control directory.
# 
# Usage Instructions (Terminal Evaluation):
# - Because this utility sources functions into your active shell environment, it MUST
#   be evaluated using the shell built-in 'source' or '.' command.
# 
# ```bash
#   # Example 1: Execution using the default 'src' directory:
#   . .dev/devexec.sh
# 
#   # Example 2: Execution targeting a custom directory (e.g., 'lib/modules'):
#   . .dev/devexec.sh lib/modules
# ```
# ==============================================================================

tmp_path="${1:-src}"

while IFS= read -r -d '' file; do
  . "${file}"
done < <(find "${tmp_path}" -type f -name "*.sh" ! -name "*_test.sh" ! -name "*_autoexec.sh" -print0 | LC_ALL=C sort -z)

unset tmp_path
