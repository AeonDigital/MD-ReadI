#!/usr/bin/env bash

# _GLOBAL_VARIABLE_: EXPORT_PACKAGE_REGISTER
# 
# Description:
# - An indexed array acting as the central registry for multi-package compilation pipelines.
# - Stores the foundational names of all packages intended to be built during the pre-commit hook phase.
# - Every entry registered here acts as a strict structural token used to dynamically map, 
#   resolve, and load its corresponding associative configuration array.
# 
# Usage Notes:
# - Names should be written in PascalCase or Pascal-Kebab-Case (e.g., "Shell-Formatter").
# - For each entry "X" added here, a matching associative array named 'EXPORT_PACKAGE_<UPPERCASE_X_SNAKE_CASE>' 
#   must be explicitly declared and populated below.
# 
# Workflow Integration Step Blueprint:
# 1. Choose a unique identification name for your package (e.g., "My-New-Package").
# 2. Append this name as a new string entry inside the 'EXPORT_PACKAGE_REGISTER' array.
# 3. Create a corresponding global associative array following the naming convention:
#    EXPORT_PACKAGE_<UPPERCASE_SNAKE_CASE_NAME>
#    (e.g., "My-New-Package" becomes EXPORT_PACKAGE_MY_NEW_PACKAGE)
# 
# Reference Schematic Blueprint:
# declare -gA EXPORT_PACKAGE_<UPPERCASE_SNAKE_CASE_NAME>=()
# EXPORT_PACKAGE_<UPPERCASE_SNAKE_CASE_NAME>["project_url"]=""          # Required
# EXPORT_PACKAGE_<UPPERCASE_SNAKE_CASE_NAME>["project_name"]=""         # Required
# EXPORT_PACKAGE_<UPPERCASE_SNAKE_CASE_NAME>["project_license_type"]="" # Required
# EXPORT_PACKAGE_<UPPERCASE_SNAKE_CASE_NAME>["project_license_url"]=""  # Required
# EXPORT_PACKAGE_<UPPERCASE_SNAKE_CASE_NAME>["project_root_path"]=""    # Required
# EXPORT_PACKAGE_<UPPERCASE_SNAKE_CASE_NAME>["source_dir_path"]=""      # Optional
# EXPORT_PACKAGE_<UPPERCASE_SNAKE_CASE_NAME>["assets_dir_path"]=""      # Optional
# EXPORT_PACKAGE_<UPPERCASE_SNAKE_CASE_NAME>["export_file_path"]=""     # Optional
# EXPORT_PACKAGE_<UPPERCASE_SNAKE_CASE_NAME>["use_autoexec"]=""         # Optional
declare -ga EXPORT_PACKAGE_REGISTER=()





# (Add your custom package configuration arrays below this line)