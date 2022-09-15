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
  local binary_folder job_jar_relative_path log_archive

  if [[ "$#" != "3" ]]; then
    echo "Usage: <binary-folder> <relative-path-to-job-jar> <logs-archive-path>"
    return 1
  fi
 
  binary_folder=$1
  job_jar_relative_path=$2
  log_archive=$3

  if [[ ! -d ${binary_folder} ]]; then
    echo "Error: ${binary_folder} is not a directory."
    return 1
  fi

  ${binary_folder}/bin/start-cluster.sh
  ${binary_folder}/bin/flink run ${binary_folder}/${job_jar_relative_path}
  ${binary_folder}/bin/stop-cluster.sh

  tar -czf ${log_archive} -C ${binary_folder} log
  rm -f ${binary_folder}/log/*
}
