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

function check_maven_version() {
  local maven_exec

  if [[ "$#" != "1" ]]; then
    echo "Usage: <maven-executable>"
    return 1
  fi

  maven_exec=$1

  if ! which $maven_exec &> /dev/null; then
    echo "Error: Maven executable '${maven_exec}' not found."
    return 1
  elif ! grep --quiet "Apache Maven 3.2.5" <($maven_exec --version); then
    echo "Error: Wrong Maven version used. Only 3.2.5 is supported."
    $maven_exec --version
    return 1
  fi 
}

function build_flink() {
  local working_directory source_directory maven_exec

  if [[ "$#" != 3 ]]; then
    echo "Usage: <working-directory> <source_directory> <maven_exec>"
    return 1
  fi

  working_directory=$1
  source_directory=$2
  maven_exec=$3

  $maven_exec -f ${source_directory}/pom.xml -T1C -DskipTests -pl flink-dist -am package 2>&1 | tee ${working_directory}/source-build.out
}
