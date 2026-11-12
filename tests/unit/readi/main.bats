#!/usr/bin/env bats

setup() {
  bats_require_minimum_version 1.5.0
  source "${BATS_TEST_DIRNAME}/../../../src/readi/main.sh"
  TEST_ROOT="${BATS_TEST_TMPDIR}/case"
  mkdir -p "${TEST_ROOT}"

  shell_md_readi_process_file() {
    printf "CALL <%s> <%s>\n" "$1" "$2"
    return "${MOCK_STATUS:-0}"
  }
}

@test "missing and empty source fail on stderr before invoking the processor" {
  run --separate-stderr shell_md_readi
  [[ $status -eq 1 && -z $output && $stderr == "[ERR] :: Missing source path. Provide a file or directory." ]]
  run --separate-stderr shell_md_readi "" "${TEST_ROOT}/out"
  [[ $status -eq 1 && -z $output && $stderr == "[ERR] :: Missing source path. Provide a file or directory." ]]
}

@test "nonexistent source and dangling symlink fail on stderr" {
  local missing="${TEST_ROOT}/missing.md" link="${TEST_ROOT}/dangling.md"
  ln -s "$missing" "$link"
  run --separate-stderr shell_md_readi "$missing"
  [[ $status -eq 1 && -z $output && $stderr == "[ERR] :: Source path '${missing}' does not exist." ]]
  run --separate-stderr shell_md_readi "$link"
  [[ $status -eq 1 && -z $output && $stderr == "[ERR] :: Source path '${link}' does not exist." ]]
}

@test "file extension validation is case sensitive and precedes destination validation" {
  local file target="${TEST_ROOT}/destination"
  mkdir -p "$target"
  for file in "${TEST_ROOT}/plain" "${TEST_ROOT}/wrong.txt" "${TEST_ROOT}/upper.MD" "${TEST_ROOT}/suffix.md.bak"; do
    touch "$file"
    run --separate-stderr shell_md_readi "$file" "$target"
    [[ $status -eq 1 && -z $output && $stderr == "[ERR] :: Source file '${file}' is not a Markdown (.md) file." ]] || return 1
  done
}

@test "file routes omitted and empty destination in place without removing source" {
  local file="${TEST_ROOT}/source with spaces.md"
  touch "$file"
  run --separate-stderr shell_md_readi "$file"
  [[ $status -eq 0 && -z $stderr && $output == "CALL <${file}> <${file}>" && -f $file ]]
  run --separate-stderr shell_md_readi "$file" ""
  [[ $status -eq 0 && -z $stderr && $output == "CALL <${file}> <${file}>" && -f $file ]]
}

@test "file routes arbitrary non-directory destinations without creating them" {
  local file="${TEST_ROOT}/source.md" target="${TEST_ROOT}/new dir/output.txt"
  touch "$file"
  run --separate-stderr shell_md_readi "$file" "$target"
  [[ $status -eq 0 && -z $stderr && $output == "CALL <${file}> <${target}>" && ! -e $target && ! -e ${TEST_ROOT}/new\ dir ]]
  touch "${TEST_ROOT}/existing"
  run --separate-stderr shell_md_readi "$file" "${TEST_ROOT}/existing"
  [[ $status -eq 0 && -z $stderr && $output == "CALL <${file}> <${TEST_ROOT}/existing>" ]]
}

@test "file rejects a directory destination" {
  local file="${TEST_ROOT}/source.md"
  touch "$file"
  run --separate-stderr shell_md_readi "$file" "$TEST_ROOT"
  [[ $status -eq 1 && -z $output && $stderr == "[ERR] :: Second argument must be a file path when source is a file." ]]
}

@test "non-file non-directory source is rejected" {
  local fifo="${TEST_ROOT}/pipe"
  mkfifo "$fifo"
  run --separate-stderr shell_md_readi "$fifo"
  [[ $status -eq 1 && -z $output && $stderr == "[ERR] :: Unsupported source path '${fifo}'." ]]
}

@test "empty directory reports no Markdown before validating or creating target" {
  local source="${TEST_ROOT}/empty" target="${TEST_ROOT}/new-target"
  mkdir -p "$source"
  touch "${source}/other.txt" "${source}/upper.MD"
  run --separate-stderr shell_md_readi "$source" "$target"
  [[ $status -eq 0 && -z $stderr && $output == "[ ! ] :: No Markdown (.md) files found under '${source}'." && ! -e $target ]]
  touch "${TEST_ROOT}/existing-target"
  run --separate-stderr shell_md_readi "$source" "${TEST_ROOT}/existing-target"
  [[ $status -eq 0 && -z $stderr && $output == "[ ! ] :: No Markdown (.md) files found under '${source}'." ]]
}

@test "directory rejects an existing file destination when markdown exists" {
  local source="${TEST_ROOT}/source" target="${TEST_ROOT}/target"
  mkdir -p "$source"
  touch "${source}/a.md" "$target"
  run --separate-stderr shell_md_readi "$source" "$target"
  [[ $status -eq 1 && -z $output && $stderr == "[ERR] :: Second argument must be a directory path when source is a directory." ]]
}

@test "directory dispatches visible markdown recursively in order and in place" {
  local source="${TEST_ROOT}/source"
  mkdir -p "${source}/nested" "${source}/.hidden"
  touch "${source}/a.md" "${source}/nested/b space.md" "${source}/nested/c.txt" "${source}/.hidden/no.md" "${source}/.hidden.md"
  run --separate-stderr shell_md_readi "$source"
  [[ $status -eq 0 && -z $stderr && ${#lines[@]} -eq 2 ]]
  [[ ${lines[0]} == "CALL <${source}/a.md> <${source}/a.md>" ]]
  [[ ${lines[1]} == "CALL <${source}/nested/b space.md> <${source}/nested/b space.md>" ]]
}

@test "directory creates target root and maps relative paths without creating files" {
  local source="${TEST_ROOT}/source" target="${TEST_ROOT}/target/new"
  mkdir -p "${source}/nested"
  touch "${source}/a.md" "${source}/nested/b.md"
  run --separate-stderr shell_md_readi "$source" "$target"
  [[ $status -eq 0 && -z $stderr && ${#lines[@]} -eq 2 && -d $target ]]
  [[ ${lines[0]} == "CALL <${source}/a.md> <${target}/a.md>" ]]
  [[ ${lines[1]} == "CALL <${source}/nested/b.md> <${target}/nested/b.md>" ]]
  [[ ! -e ${target}/a.md && ! -e ${target}/nested ]]
  run --separate-stderr shell_md_readi "$source" "$target"
  [[ $status -eq 0 && -z $stderr && ${#lines[@]} -eq 2 ]]
}

@test "directory source with trailing slash still mirrors the relative layout" {
  local source="${TEST_ROOT}/source" target="${TEST_ROOT}/target"
  mkdir -p "${source}/nested"
  touch "${source}/nested/b.md"
  run --separate-stderr shell_md_readi "${source}/" "$target"
  [[ $status -eq 0 && -z $stderr ]]
  [[ $output == "CALL <${source}//nested/b.md> <${target}/nested/b.md>" ]]
}

@test "processor failure for a file must not be reported as successful processing" {
  local file="${TEST_ROOT}/source.md"
  touch "$file"
  MOCK_STATUS=1
  run --separate-stderr shell_md_readi "$file"
  [[ $output == "CALL <${file}> <${file}>" && -z $stderr ]]
  [[ $status -ne 0 ]]
}

@test "processor failure for a directory must not be reported as successful processing" {
  local source="${TEST_ROOT}/source"
  mkdir -p "$source"
  touch "${source}/a.md"
  MOCK_STATUS=1
  run --separate-stderr shell_md_readi "$source"
  [[ $output == "CALL <${source}/a.md> <${source}/a.md>" && -z $stderr ]]
  [[ $status -ne 0 ]]
}

@test "directory enumeration disables globstar and nullglob after dispatch" {
  local source="${TEST_ROOT}/source"
  mkdir -p "$source"
  touch "${source}/a.md"
  shopt -s globstar nullglob
  shell_md_readi "$source"
  ! shopt -q globstar
  ! shopt -q nullglob
}

@test "relative source and target paths are passed through and mapped" {
  mkdir -p "${TEST_ROOT}/source/nested"
  touch "${TEST_ROOT}/source/nested/a.md"
  cd "$TEST_ROOT"
  run --separate-stderr shell_md_readi source target
  [[ $status -eq 0 && -z $stderr && $output == "CALL <source/nested/a.md> <target/nested/a.md>" && -d target ]]
  run --separate-stderr shell_md_readi source/nested/a.md output.md
  [[ $status -eq 0 && -z $stderr && $output == "CALL <source/nested/a.md> <output.md>" ]]
}

@test "symlinks to an existing markdown file and directory use the provided paths" {
  local source="${TEST_ROOT}/source" filelink="${TEST_ROOT}/file.md" dirlink="${TEST_ROOT}/directory"
  mkdir -p "$source"
  touch "${source}/a.md"
  ln -s "${source}/a.md" "$filelink"
  ln -s "$source" "$dirlink"
  run --separate-stderr shell_md_readi "$filelink"
  [[ $status -eq 0 && -z $stderr && $output == "CALL <${filelink}> <${filelink}>" ]]
  run --separate-stderr shell_md_readi "$dirlink" "${TEST_ROOT}/target"
  [[ $status -eq 0 && -z $stderr && $output == "CALL <${dirlink}/a.md> <${TEST_ROOT}/target/a.md>" ]]
}
