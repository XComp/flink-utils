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

function run_flink_session_cluster() {
  echo "### run_flink_session_cluster $@"
  local working_directory label binary_folder job_jar_relative_path

  if [[ "$#" != "4" ]]; then
    echo "Usage: <working-directory> <label> <binary-folder> <relative-path-to-job-jar>"
    return 1
  fi
 
  working_directory=$1
  label=$2
  binary_folder=$3
  job_jar_relative_path=$4

  if [[ ! -d ${binary_folder} ]]; then
    echo "Error: ${binary_folder} is not a directory."
    return 1
  fi

  ${binary_folder}/bin/start-cluster.sh
  ${binary_folder}/bin/flink run ${binary_folder}/${job_jar_relative_path}
  ${binary_folder}/bin/stop-cluster.sh

  mv ${binary_folder}/log ${binary_folder}/log-${label} 
  tar -czf ${working_directory}/${label}.tgz -C ${binary_folder} log-${label}
  rm -rf ${binary_folder}/log-${label}
  mkdir ${binary_folder}/log
}
