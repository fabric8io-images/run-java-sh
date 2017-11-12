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
  [[ $output == *"JVM::$1"* ]]
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
