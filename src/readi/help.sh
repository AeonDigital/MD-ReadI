#!/usr/bin/env bash

# shell_md_readi_help — Display the CLI manual and geometric usage guide for the
# Markdown Readability Initiative formatter engine.
# 
# Returns:
# - Outputs the formatted plain-text technical manual to stdout.
shell_md_readi_help() {
  local msg=""

  msg+="NAME${codeNL}"
  msg+="  shell_md_readi - Linter and layout restructuring engine enforcing the MD-ReadI standard${codeNL}${codeNL}"

  msg+="SUMMARY${codeNL}"
  msg+="  shell_md_readi <source_path> [target_path]${codeNL}${codeNL}"

  msg+="DESCRIPTION${codeNL}"
  msg+="  An automated plain-text layout engine that normalizes Markdown (.md) documents to${codeNL}"
  msg+="  prioritize 'Human Readability First'. It eliminates HTML preview dependencies by${codeNL}"
  msg+="  reconstructing raw text into a deterministic, scannable terminal graphical canvas.${codeNL}"
  msg+="  The engine runs a two-phase architecture: a linear Canonization phase that purges${codeNL}"
  msg+="  Unicode anomalies, un-wraps loose prose, and standardizes list/table markers; followed by${codeNL}"
  msg+="  a Stateful Formatting phase that re-wraps text within a tight 80-120 comfort window,${codeNL}"
  msg+="  unifies rhythmic horizontal dividers, and scales vertical voids using content density.${codeNL}${codeNL}"

  msg+="ARGUMENTS${codeNL}"
  msg+="  \$1  source_path          The file system pathway pointing to the source script context to${codeNL}"
  msg+="                            be processed. Can accept an individual Markdown (.md) file or a${codeNL}"
  msg+="                            directory containing multiple documentation files for recursive lookup.${codeNL}"
  msg+="                            * Required.${codeNL}${codeNL}"
  msg+="  \$2  target_path          Optional. The file system destination path where the beautifully${codeNL}"
  msg+="                            formatted stream will be written. If source is a directory, this${codeNL}"
  msg+="                            argument must point to a target directory (mirrored tree layout).${codeNL}"
  msg+="                            If omitted, empty, or missing, it defaults to dynamic in-place${codeNL}"
  msg+="                            overwriting of the input file context.${codeNL}${codeNL}"

  msg+="RETURN CODES${codeNL}"
  msg+="  0   Success               The document stream was successfully validated, canonized, and wrapped.${codeNL}"
  msg+="  1   Failure               Process aborted due to missing paths, invalid extensions, or runtime crashes.${codeNL}${codeNL}"

  msg+="EXAMPLES${codeNL}"
  msg+="  Standard document optimization overwriting the source Markdown file context:${codeNL}"
  msg+="      shell_md_readi \"README.md\"${codeNL}${codeNL}"
  msg+="  Layout compilation directing the stream results into a separate output pathway:${codeNL}"
  msg+="      shell_md_readi \"docs/SPECS.md\" \"build/OUTPUT_SPECS.md\"${codeNL}${codeNL}"
  msg+="  Recursive project-wide documentation normalization targeting an entire folder context:${codeNL}"
  msg+="      shell_md_readi \"./docs\" \"./dist_docs\"${codeNL}"

  echo -e "${msg}"
}
