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

function print_usage() {
  echo "print_usage method stub: This method should be overwritten in the calling script."
}

function print_info_and_exit() {
  local script_name function_description

  if [[ "$#" -lt 3 ]]; then
    echo "Usage: <script_exec_name> <function_description> <tasks> ..."
    return 1
  fi

  script_name="$0"
  function_description="$1"
  shift 2

  echo "${script_name} verifies ${function_description}. The following steps are executed:"
  for task in "$@"; do
    echo "- ${task}"
  done

  echo ""
  echo "See usage info below for further details on how to use the script..."
  print_usage

  exit 0
}

function print_mailing_list_post() {
  echo "### print_mailing_list_post $@"
  
  if [[ "$#" < 2 ]]; then
    echo "Usage: <working-directory> <tasks>"
    return 1
  fi

  out_file="$1/mailing_list.out"
  shift

  echo "+1 (non-binding)" | tee ${out_file}
  echo "" | tee -a ${out_file}
  for task in "$@"; do
    echo "* ${task}" | tee -a ${out_file}
  done
}
