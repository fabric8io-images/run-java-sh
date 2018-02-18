# Helper functions

mktmpdir() {
  local d="$BATS_TMPDIR/$1"
  [ -d $dir ] && rm -rf $d
  mkdir $d
  echo $d
}

assert_regexp() {
  [[ $output =~ $1 ]]
}

assert_status() {
  [ $status = $1 ]
}

assert_env() {
  assert_key_value_param "ENV::" $1 $2
}

assert_sysprop() {
  assert_key_value_param "PROP::" $1 $2
}

assert_arg() {
  [[ $output == *"ARG::$1"* ]]
}

assert_jvmarg() {
  get_jvmarg $1
}

assert_ps() {
  local val=$(extract_via_regexp "PS::" "[^"$'\n'"]*$1[^"$'\n'"]*")
  [ -n "$val" ]
}
assert_command_contains() {
  [[ $lines[0] == *"$1"* ]]
}

assert_command_contains_not() {
  [[ $lines[0] != *"$1"* ]]
}

assert_key_value_param() {
  local prefix="$1"
  local key="$2"
  local expected="$3"
  local val=$(extract_key_value_from_output "$prefix" "$key")
  [ "$expected" = "$val" ]
}

# Get env. Must be run in a subshell, value as output
get_env() {
  extract_key_value_from_output "ENV::" "$1"
}

get_sysprop() {
  extract_key_value_from_output "PROP::" "$1"
}

get_jvmarg() {
  extract_via_regexp "JVM::" ".*${1}.*"
}

get_arg() {
  extract_via_regexp "ARG::" ".*${1}.*"
}

create_non_exec_run_script() {
  local out=$1
  local extra=$2
  local tmp_dir=$(dirname ${out})
  local script=$(cat $RUN_JAVA | sed -e 's/^[[:space:]]*exec[[:space:]]/#  exec /g')

  cat - <<EOT >$out
$script
echo
$extra
EOT

  cp ${RUN_JAVA_DIR}/container-limits ${tmp_dir}
  cp ${RUN_JAVA_DIR}/java-default-options ${tmp_dir}
}

extract_key_value_from_output() {
  local prefix=$1
  local key=$2
  local re="${prefix}${key}=([^"$'\n'"]*)"
  [[ $output =~ $re ]] && echo "${BASH_REMATCH[1]}"
}

extract_via_regexp() {
  local prefix=$1
  local tomatch=$2
  local re="${prefix}(${tomatch})"$'\n'
  [[ $output =~ $re ]] && echo "${BASH_REMATCH[1]}"
}

ceiling() {
  echo $1 | awk '
    function ceiling(x){
      return x%1 ? int(x)+1 : x
    }
    {
      print ceiling($1)
    }
  '
}
