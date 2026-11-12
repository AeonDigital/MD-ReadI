#!/usr/bin/env bats

setup() {
  bats_require_minimum_version 1.5.0
  source "${BATS_TEST_DIRNAME}/../../../src/share/00_vars.sh"
  source "${BATS_TEST_DIRNAME}/../../../src/readi/parse.sh"
}

# Bats run isolates global state; call again in this shell to inspect the matrices.
parse_silently() {
  local input=$1
  run --separate-stderr shell_md_readi_parse "$input"
  [[ $status -eq 0 && -z $output && -z $stderr ]] || return 1
  if shell_md_readi_parse "$input"; then return 0; else return 1; fi
}

assert_blocks() {
  local expected_count=$# i actual expected
  for actual in "${#SHELL_MD_READI_BLOCK_TYPE[@]}" "${#SHELL_MD_READI_BLOCK_START[@]}" \
    "${#SHELL_MD_READI_BLOCK_END[@]}" "${#SHELL_MD_READI_BLOCK_LINES[@]}" \
    "${#SHELL_MD_READI_BLOCK_HAS_SEP[@]}" "${#SHELL_MD_READI_BLOCK_LAST_RELEVANT[@]}"; do
    if [[ $actual -ne $expected_count ]]; then
      printf "expected %d entries in each matrix, found %d\n" "$expected_count" "$actual" >&2
      return 1
    fi
  done
  for ((i = 0; i < expected_count; i++)); do
    expected=${1}
    shift
    printf -v actual "%s|%s|%s|%s|%s|%s" \
      "${SHELL_MD_READI_BLOCK_TYPE[i]}" "${SHELL_MD_READI_BLOCK_START[i]}" \
      "${SHELL_MD_READI_BLOCK_END[i]}" "${SHELL_MD_READI_BLOCK_LINES[i]}" \
      "${SHELL_MD_READI_BLOCK_HAS_SEP[i]}" "${SHELL_MD_READI_BLOCK_LAST_RELEVANT[i]}"
    if [[ $actual != "$expected" ]]; then
      printf "block %d: expected <%s>, got <%s>\n" "$i" "$expected" "$actual" >&2
      return 1
    fi
  done
}

@test "empty or omitted input clears stale matrices and represents one empty line" {
  SHELL_MD_READI_BLOCK_TYPE=(stale stale)
  SHELL_MD_READI_BLOCK_START=(9 10)
  SHELL_MD_READI_BLOCK_END=(9 10)
  SHELL_MD_READI_BLOCK_LINES=(9 10)
  SHELL_MD_READI_BLOCK_HAS_SEP=(1 1)
  SHELL_MD_READI_BLOCK_LAST_RELEVANT=(stale stale)
  if shell_md_readi_parse; then :; else return 1; fi
  assert_blocks "EMPTY_LINE|1|1|1|0|"
  parse_silently ""
  assert_blocks "EMPTY_LINE|1|1|1|0|"
}

@test "paragraph continuity ends at blank lines and preserves last relevant context" {
  printf -v input "%b" "first\nsecond\n   \nthird\nfourth"
  parse_silently "$input"
  assert_blocks "PARAGRAPH|1|1|1|0|" "PARAGRAPH|2|2|1|0|SAME_PARAGRAPH" \
    "EMPTY_LINE|3|3|1|0|PARAGRAPH" "PARAGRAPH|4|4|1|0|PARAGRAPH" \
    "PARAGRAPH|5|5|1|0|SAME_PARAGRAPH"
}

@test "trailing newline adds a physical empty line" {
  printf -v input "%b" "text\n"
  parse_silently "$input"
  assert_blocks "PARAGRAPH|1|1|1|0|" "EMPTY_LINE|2|2|1|0|PARAGRAPH"
}

@test "headers use trimmed text and retain prior structural context" {
  printf -v input "%b" " # title\n## next\nbody"
  parse_silently "$input"
  assert_blocks "HEADER|1|1|1|0|" "HEADER|2|2|1|0|HEADER" "PARAGRAPH|3|3|1|0|HEADER"
}

@test "nbsp metadata marks a positive separator and header consumes it" {
  printf -v input "%b" "&nbsp; 1/2/3\n&nbsp; 1/0/3\n# title\n# next"
  parse_silently "$input"
  assert_blocks "NBSP_BLOCK|1|1|1|1|" "NBSP_BLOCK|2|2|1|1|" \
    "HEADER|3|3|1|1|" "HEADER|4|4|1|0|HEADER"
}

@test "zero metadata and non-header content do not carry a separator to the next header" {
  printf -v input "%b" "&nbsp; 1/0/3\n# first\n&nbsp; 1/1/3\ntext\n# second"
  parse_silently "$input"
  assert_blocks "NBSP_BLOCK|1|1|1|0|" "HEADER|2|2|1|0|" \
    "NBSP_BLOCK|3|3|1|1|HEADER" "PARAGRAPH|4|4|1|0|HEADER" "HEADER|5|5|1|0|PARAGRAPH"
}

@test "blank lines preserve separator state for a subsequent header" {
  printf -v input "%b" "&nbsp; 0/1/0\n\n# heading"
  parse_silently "$input"
  assert_blocks "NBSP_BLOCK|1|1|1|1|" "EMPTY_LINE|2|2|1|0|" "HEADER|3|3|1|1|"
}

@test "a fenced code block protects all other token types and closes on a trimmed fence" {
  printf -v input "%b" "before\n\`\`\`bash\n# not header\n\n&nbsp; 1/1/1\n  \`\`\`\nafter"
  parse_silently "$input"
  assert_blocks "PARAGRAPH|1|1|1|0|" "CODE_BLOCK|2|6|5|0|PARAGRAPH" \
    "PARAGRAPH|7|7|1|0|CODE_BLOCK"
}

@test "code fence flushes an active structure before beginning the code block" {
  printf -v input "%b" "> quote\n\`\`\`\ninside\n\`\`\`\n# header"
  parse_silently "$input"
  assert_blocks "BLOCKQUOTE|1|1|1|0|" "CODE_BLOCK|2|4|3|0|BLOCKQUOTE" \
    "HEADER|5|5|1|0|CODE_BLOCK"
}

@test "unfinished code fence is discarded at end of input" {
  printf -v input "%b" "\`\`\`\ncode"
  parse_silently "$input"
  assert_blocks
}

@test "metadata flushes a structure and preserves the separator for a header" {
  printf -v input "%b" "- item\n&nbsp; 1/1/1\n# heading"
  parse_silently "$input"
  assert_blocks "LIST|1|1|1|0|" "NBSP_BLOCK|2|2|1|1|LIST" "HEADER|3|3|1|1|LIST"
}

@test "header, empty line, and separator each flush an active structure" {
  printf -v input "%b" "> a\n# h\n| b\n\n- c\n---\nprose"
  parse_silently "$input"
  assert_blocks "BLOCKQUOTE|1|1|1|0|" "HEADER|2|2|1|0|BLOCKQUOTE" \
    "TABLE|3|3|1|0|HEADER" "EMPTY_LINE|4|4|1|0|TABLE" \
    "LIST|5|5|1|0|TABLE" "SEPARATOR|6|6|1|0|LIST" "PARAGRAPH|7|7|1|0|LIST"
}

@test "adjacent repeated structural lines and nonmatching continuation form blocks" {
  printf -v input "%b" "> a\n> b\ncontinuation\n<div>\n</div>\nhtml content\n| a |\n| b |\ntable content\n- a\n1. b\nlist content"
  parse_silently "$input"
  assert_blocks "BLOCKQUOTE|1|3|3|0|" "HTML_BLOCK|4|6|3|0|BLOCKQUOTE" \
    "TABLE|7|9|3|0|HTML_BLOCK" "LIST|10|12|3|0|TABLE"
}

@test "each structural state starts after free text and flushes on end of input" {
  local input type text
  for type in BLOCKQUOTE HTML_BLOCK TABLE LIST; do
    case $type in
      BLOCKQUOTE) text="> quote" ;;
      HTML_BLOCK) text="<div>" ;;
      TABLE) text="| cell |" ;;
      LIST) text="- item" ;;
    esac
    parse_silently "$text"
    assert_blocks "$type|1|1|1|0|"
    printf -v input "%b%s" "text\n" "$text"
    parse_silently "$input"
    assert_blocks "PARAGRAPH|1|1|1|0|" "$type|2|2|1|0|PARAGRAPH"
  done
}

@test "transitions into quote, html, table and list flush previous active blocks" {
  printf -v input "%b" "- a\n> b\n<div>\n| c |\n* d"
  parse_silently "$input"
  assert_blocks "LIST|1|1|1|0|" "BLOCKQUOTE|2|2|1|0|LIST" \
    "HTML_BLOCK|3|3|1|0|BLOCKQUOTE" "TABLE|4|4|1|0|HTML_BLOCK" "LIST|5|5|1|0|TABLE"
}

@test "separator precedence, metadata anchoring, and malformed markers" {
  printf -v input "%b" "  ---  \n  &nbsp; 0/1/0\n- x\n--\n\n# h"
  parse_silently "$input"
  assert_blocks "SEPARATOR|1|1|1|0|" "PARAGRAPH|2|2|1|0|" \
    "LIST|3|4|2|0|PARAGRAPH" "EMPTY_LINE|5|5|1|0|LIST" "HEADER|6|6|1|0|LIST"
}

@test "repeated calls reset every matrix and do not retain structural context" {
  printf -v input "%b" "> one\n> two\n# title"
  parse_silently "$input"
  assert_blocks "BLOCKQUOTE|1|2|2|0|" "HEADER|3|3|1|0|BLOCKQUOTE"
  parse_silently "plain"
  assert_blocks "PARAGRAPH|1|1|1|0|"
}
