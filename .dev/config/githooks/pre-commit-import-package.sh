#!/usr/bin/env bash

# _GLOBAL_VARIABLE_: IMPORT_PACKAGE_REGISTER
# 
# Description:
# - An indexed array acting as the central registry for multi-package upstream provisioning pipelines.
# - Stores the foundational names of all external tools intended to be fetched during the pre-commit hook phase.
# - Every entry registered here acts as a strict structural token used to dynamically map, 
#   resolve, and load its corresponding associative configuration array.
# 
# Usage Notes:
# - Names should be written in PascalCase or Pascal-Kebab-Case (e.g., "My-External-Tool").
# - For each entry "X" added here, a matching associative array named 'IMPORT_PACKAGE_<UPPERCASE_X_SNAKE_CASE>' 
#   must be explicitly declared and populated below.
# 
# Workflow Integration Step Blueprint:
# 1. Choose a unique identification name for your package (e.g., "My-External-Tool").
# 2. Append this name as a new string entry inside the 'IMPORT_PACKAGE_REGISTER' array.
# 3. Create a corresponding global associative array following the naming convention:
#    IMPORT_PACKAGE_<UPPERCASE_SNAKE_CASE_NAME>
#    (e.g., "My-External-Tool" becomes IMPORT_PACKAGE_MY_EXTERNAL_TOOL)
# 
# Reference Schematic Blueprint:
# declare -gA IMPORT_PACKAGE_<UPPERCASE_SNAKE_CASE_NAME>=()
# IMPORT_PACKAGE_<UPPERCASE_SNAKE_CASE_NAME>["upstream_base_url"]=""  # Required (e.g., "https://raw.githubusercontent.com")
# IMPORT_PACKAGE_<UPPERCASE_SNAKE_CASE_NAME>["package_name"]=""       # Required (The repository or directory identifier)
# IMPORT_PACKAGE_<UPPERCASE_SNAKE_CASE_NAME>["package_filename"]=""   # Required (The physical remote standalone script name)
declare -ga IMPORT_PACKAGE_REGISTER=()





# (Add your custom package configuration arrays below this line)