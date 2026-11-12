#!/usr/bin/env bats

# Summary: Load the newline register and the function under test.
# Effects: Initializes the global result register.
setup() {
  bats_require_minimum_version 1.5.0
  export LC_ALL=C.UTF-8
  . "${BATS_TEST_DIRNAME}/../../../../src/share/00_vars.sh"
  . "${BATS_TEST_DIRNAME}/../../../../src/readi/canonize/06_table_cells.sh"
}

# Summary: Call the function with a sentinel on each output channel.
# Parameters: All arguments are forwarded to the function.
# Returns: The function status and a sentinel on each channel.
# Effects: Updates the result global in the Bats run subshell.
invoke_with_sentinels() {
  local rc=0
  shell_md_readi_canonize_table_cells "${@}" || rc=${?}
  printf "%s" stdout-sentinel
  printf "%s" stderr-sentinel >&2
  return "${rc}"
}

# Summary: Check status, both channels, and the exact result register.
# Parameters: $1 input and $2 expected output, using printf %b escapes.
# Returns: Zero on a match; otherwise nonzero with a diagnostic.
# Effects: Calls the function twice and updates the result global.
assert_table() {
  local input=""
  local expected=""
  printf -v input "%b" "${1}"
  printf -v expected "%b" "${2}"
  run --separate-stderr invoke_with_sentinels "${input}"
  [[ ${status} -eq 0 && ${output} == stdout-sentinel && ${stderr} == stderr-sentinel ]] || return 1
  shell_md_readi_canonize_table_cells "${input}" || return 1
  if [[ ${SHELL_MD_READI_RESULT_CANONIZE_TABLE_CELLS} != "${expected}" ]]; then
    printf "expected %q, got %q\n" "${expected}" "${SHELL_MD_READI_RESULT_CANONIZE_TABLE_CELLS}" >&2
    return 1
  fi
}

@test "empty input replaces stale output with one newline" {
  SHELL_MD_READI_RESULT_CANONIZE_TABLE_CELLS=stale
  assert_table "" "\n"
}

@test "omitted argument behaves like empty input" {
  local expected=""
  SHELL_MD_READI_RESULT_CANONIZE_TABLE_CELLS=stale
  run --separate-stderr invoke_with_sentinels
  [ "${status}" -eq 0 ]
  [ "${output}" = stdout-sentinel ]
  [ "${stderr}" = stderr-sentinel ]
  shell_md_readi_canonize_table_cells
  printf -v expected "%b" "\n"
  [ "${SHELL_MD_READI_RESULT_CANONIZE_TABLE_CELLS}" = "${expected}" ]
}

@test "ordinary lines retain whitespace and blank boundaries" {
  assert_table "  prose  \n\tmore\t\n\nend" "  prose  \n\tmore\t\n\nend\n"
}

@test "trailing newlines add empty physical lines" {
  assert_table "|a|\n" "| a |\n\n"
  assert_table "x\n\n" "x\n\n\n"
}

@test "both outer pipes are needed for row recognition" {
  assert_table "|\n| a\na |\npre |a|\n|a| post" "|\n| a\na |\npre |a|\n|a| post\n"
}

@test "outer and cell whitespace is trimmed for rows" {
  assert_table " \t|  alpha  |\tbeta\t|  \t" "| alpha | beta |\n"
}

@test "internal cell whitespace and punctuation remain unchanged" {
  assert_table "| a  b | x\ty | **bold** [link](url) |" "| a  b | x\ty | **bold** [link](url) |\n"
}

@test "one and multiple cells normalize without a header" {
  assert_table "|a|\n|b|c|d|" "| a |\n| b | c | d |\n"
}

@test "empty cells including first middle and last are retained" {
  assert_table "||\n|||\n||a||b||" "|  |\n|  |  |\n|  | a |  | b |  |\n"
  assert_table "|  |\t |" "|  |  |\n"
}

@test "backslash is preserved but does not escape a cell delimiter" {
  assert_table "|a\\\\|b|" "| a\\\\ | b |\n"
}

@test "each divider alignment gets its canonical token" {
  assert_table "|---|:---|---:|:---:|" "| ----- | :---- | ----: | :---: |\n"
}

@test "one dash is sufficient and dash lengths are normalized" {
  assert_table "|-|:-|-:|:-:|\n|-----|:-------|--------:|:---------:|" "| ----- | :---- | ----: | :---: |\n| ----- | :---- | ----: | :---: |\n"
}

@test "divider cell and row whitespace is trimmed" {
  assert_table " \t|\t :--: \t| :--- | ---: | --- | \t" "| :---: | :---- | ----: | ----- |\n"
}

@test "empty and colon-only cells prevent divider recognition" {
  assert_table "||---|\n|---||\n|:|---|\n|::|---|" "|  | --- |\n| --- |  |\n| : | --- |\n| :: | --- |\n"
}

@test "invalid divider characters and misplaced colons make the entire row ordinary" {
  assert_table "|--x|---|\n|--:--|:-|\n|-- --|---|\n|=|---|" "| --x | --- |\n| --:-- | :- |\n| -- -- | --- |\n| = | --- |\n"
}

@test "rows and dividers do not depend on surrounding table context" {
  assert_table "before\n|a|b|\n|-|:-:|\nafter\n|-:|" "before\n| a | b |\n| ----- | :---: |\nafter\n| ----: |\n"
}

@test "fenced blocks preserve rows dividers and original whitespace" {
  assert_table "|a|\n\`\`\`sh\n  | a |b |  \n|-|:-:|\n\n\`\`\`\n|c|" "| a |\n\`\`\`sh\n  | a |b |  \n|-|:-:|\n\n\`\`\`\n| c |\n"
}

@test "indented fences and fence suffixes toggle code protection" {
  assert_table "  \`\`\`lang\n|a|\n\t\`\`\`suffix\n|b|" "  \`\`\`lang\n|a|\n\t\`\`\`suffix\n| b |\n"
}

@test "unclosed fence protects remainder and resets between calls" {
  assert_table "\`\`\`\n|a|\n|-|" "\`\`\`\n|a|\n|-|\n"
  assert_table "|b|" "| b |\n"
}

@test "backticks away from trimmed line start do not toggle protection" {
  assert_table "text \`\`\`\n|a|\n|\`\`\`|\n|b|" "text \`\`\`\n| a |\n| \`\`\` |\n| b |\n"
}

@test "separate fenced blocks reopen protection" {
  assert_table "\`\`\`\n|a|\n\`\`\`\n|b|\n\`\`\`\n|c|\n\`\`\`\n|d|" "\`\`\`\n|a|\n\`\`\`\n| b |\n\`\`\`\n|c|\n\`\`\`\n| d |\n"
}

@test "two backticks and tilde fences do not toggle protection" {
  assert_table "\`\`\n|a|\n~~~\n|b|" "\`\`\n| a |\n~~~\n| b |\n"
}

@test "IFS is restored after normal rows dividers and skipped lines" {
  local original_ifs=""
  original_ifs="${IFS}"
  IFS=":"
  assert_table "plain\n|a|b|\n|-|:-|\n\`\`\`\n|x|\n\`\`\`" "plain\n| a | b |\n| ----- | :---- |\n\`\`\`\n|x|\n\`\`\`\n"
  [ "${IFS}" = ":" ]
  IFS="${original_ifs}"
}

@test "successive calls replace the result without appending" {
  shell_md_readi_canonize_table_cells "|first|"
  assert_table "|second|" "| second |\n"
}
