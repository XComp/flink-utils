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
