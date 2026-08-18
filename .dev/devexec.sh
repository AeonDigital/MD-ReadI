#!/usr/bin/env bash

# devexec.sh - Dynamic development environment context loader and runtime orchestrator.
# 
# Description:
# - Recursively discovers and sources active library functions located inside the 'src'
#   directory tree directly into the running shell execution context.
# - Implements defensive filter exclusions to prevent loading unit testing structures
#   (*_test.sh) or initialization automation pathways (*_autoexec.sh).
# 
# Constraints & Logistics:
# - Operating Directory: Must be executed strictly from the project's root directory path.
# - File Location:      Stored and maintained inside the localized '.dev/' control directory.
# 
# Usage Instructions (Terminal Evaluation):
# - Because this utility sources functions into your active shell environment, it MUST
#   be evaluated using the shell built-in 'source' or '.' command.
# 
# ```bash
#   # Example execution command from the repository root:
#   . .dev/devexec.sh
# ```
# ==============================================================================

while IFS= read -r -d '' file; do
  . "${file}"
done < <(find "src" -type f -name "*.sh" ! -name "*_test.sh" ! -name "*_autoexec.sh" -print0 | LC_ALL=C sort -z)
