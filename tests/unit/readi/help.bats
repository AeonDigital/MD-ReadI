#!/usr/bin/env bats

setup() {
  bats_require_minimum_version 1.5.0
  source "${BATS_TEST_DIRNAME}/../../../src/share/00_vars.sh"
  source "${BATS_TEST_DIRNAME}/../../../src/readi/help.sh"
}

help_with_stdout_sentinel() {
  shell_md_readi_help
  printf "%s" "__stdout_end__"
}

@test "prints the complete manual to stdout with no stderr" {
  local expected=""
  printf -v expected "%s\n" \
    "NAME" \
    "  shell_md_readi - Markdown formatter enforcing the MD-ReadI standard" \
    "" \
    "SUMMARY" \
    "  shell_md_readi <source_path> [target_path]" \
    "" \
    "DESCRIPTION" \
    "  An automated plain-text layout engine that normalizes Markdown (.md) documents to" \
    "  prioritize 'Human Readability First'. It eliminates HTML preview dependencies by" \
    "  reconstructing raw text into a deterministic, scannable terminal graphical canvas." \
    "  The engine runs a two-phase architecture: a linear Canonization phase that purges" \
    "  Unicode anomalies, un-wraps loose prose, and standardizes list/table markers; followed by" \
    "  a Stateful Formatting phase that re-wraps text within a tight 80-120 comfort window," \
    "  unifies rhythmic horizontal dividers, and scales vertical voids using content density." \
    "" \
    "ARGUMENTS" \
    "  \$1  source_path          The file system pathway pointing to the source script context to" \
    "                            be processed. Can accept an individual Markdown (.md) file or a" \
    "                            directory containing multiple documentation files for recursive lookup." \
    "                            * Required." \
    "" \
    "  \$2  target_path          Optional. The file system destination path where the beautifully" \
    "                            formatted stream will be written. If source is a directory, this" \
    "                            argument must point to a target directory (mirrored tree layout)." \
    "                            If omitted, empty, or missing, it defaults to dynamic in-place" \
    "                            overwriting of the input file context." \
    "" \
    "RETURN CODES" \
    "  0   Success               The document stream was successfully validated, canonized, and wrapped." \
    "  1   Failure               Process aborted due to missing paths, invalid extensions, or runtime crashes." \
    "" \
    "EXAMPLES" \
    "  Standard document optimization overwriting the source Markdown file context:" \
    "      shell_md_readi \"README.md\"" \
    "" \
    "  Layout compilation directing the stream results into a separate output pathway:" \
    "      shell_md_readi \"docs/SPECS.md\" \"build/OUTPUT_SPECS.md\"" \
    "" \
    "  Recursive project-wide documentation normalization targeting an entire folder context:" \
    "      shell_md_readi \"./docs\" \"./dist_docs\""

  expected+=$'\n'

  run --separate-stderr help_with_stdout_sentinel
  [[ ${status} -eq 0 && -z ${stderr} && ${output} == "${expected}__stdout_end__" ]] || return 1
}

@test "ignores omitted, empty, and arbitrary arguments" {
  run --separate-stderr shell_md_readi_help
  [[ ${status} -eq 0 && -z ${stderr} ]] || return 1
  local expected=${output}

  run --separate-stderr shell_md_readi_help "" "ignored target" --help
  [[ ${status} -eq 0 && -z ${stderr} && ${output} == "${expected}" ]]
}
