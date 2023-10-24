#!/bin/bash
################################################################################
#  Licensed to the Apache Software Foundation (ASF) under one
#  or more contributor license agreements.  See the NOTICE file
#  distributed with this work for additional information
#  regarding copyright ownership.  The ASF licenses this file
#  to you under the Apache License, Version 2.0 (the
#  "License"); you may not use this file except in compliance
#  with the License.  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
################################################################################

set -o errexit
set -o nounset
set -o pipefail

print_usage() {
  echo "Usage: ./$0 <path-to-jar> <jar-content-regex> <notice-file-regex>"
  echo ""
  echo "  <path-to-jar>         Path to jar that shall be checked."
  echo "  <jar-content-regex>   grep regular expression for filtering out classes from jar that are relevant for this check."
  echo "  <notice-file-regex>   grep regular expression for filtering out lines in the jar's NOTICE file."
}

print_info_and_exit() {
  echo "$0 can be used to verify that bundled classes are mentioned in the corresponding NOTICE file."
  echo ""
  echo "Keep in mind that there might be different reasons why classes are bundled and where they are coming from."
  echo "Having a missing matching entry in the NOTICE file does not necessarily mean that the entry is missing."
  echo "Further investigation needs to take place to clarify where the bundled classes are coming from."
  echo ""
  echo "See usage info below for further details on how to use the script..."
  print_usage
  exit 0
}

print_error_with_usage_and_exit() {
  echo "Error: $1"
  print_usage
  exit 1
}

print_up_to() {
  local content line_count

  content="$1"
  line_count="$2"
  if [ "$(echo -e "${content}" | wc -l)" -gt "${line_count}" ]; then
    echo -e "${content}" | head -"${line_count}"
    echo "[...]"
  else
    echo -e "${content}"
  fi
}

if [[ "$#" == 0 ]]; then
  print_info_and_exit
elif [[ "$#" != 3 ]]; then
  print_error_with_usage_and_exit
fi

jar=$1
jar_content_regex=$2
notice_file_regex=$3

matching_classes="$(unzip -l $jar | grep $jar_content_regex)"
matching_classes_count=$(echo -e "$matching_classes" | wc -l)
matching_lines_in_notice_file="$(unzip -p $jar META-INF/NOTICE | grep $notice_file_regex)"
matching_lines_in_notice_file_count=$(echo -e "$matching_lines_in_notice_file" | wc -l)

if [[ "${matching_classes_count}" == "0" ]] && [[ "${matching_lines_in_notice_file_count}" == "0" ]]; then
  echo -e "[\e[32mCORRECT\e[0m] ${jar} does not contain any matching entries."
  exit 0
fi

if [[ "${matching_classes_count}" == 0 ]] || [[ "${matching_lines_in_notice_file_count}" == "0" ]]; then
  echo -e "[\e[33mWARNING\e[0m] ${jar} might have a mismatch."
else
  echo -e "[\e[32mCORRECT\e[0m] ${jar} has matching entries in both, the class listing and the NOTICE file:"
fi

echo "Matching classes (${matching_classes_count}):"
print_up_to "${matching_classes}" 10
echo "Matching lines in NOTICE file (${matching_lines_in_notice_file_count}):"
print_up_to "${matching_lines_in_notice_file}" 10
