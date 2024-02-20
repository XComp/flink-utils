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

function download_artifacts() {
  echo "### download_artifacts $@"
  local working_directory url download_dir_name repository_name

  if [[ "$#" != 4 ]]; then
    echo "Usage: <working-directory> <url> <download-dir-name> <repository_name>"
    return 1
  fi

  working_directory=$1
  url=$2
  download_dir_name=$3
  repository_name=$4

  local out_file
  out_file="${working_directory}/download-artifacts.out"
  wget --recursive --no-parent --directory-prefix ${working_directory} --reject "*.html,*.tmp,*.txt" "${url}/" 2>&1 | tee ${out_file}
  mv ${working_directory}/dist.apache.org/repos/dist/dev/flink/${repository_name}* ${working_directory}
  rm -rf ${working_directory}/dist.apache.org
  mv ${working_directory}/{${repository_name}*,${download_dir_name}}
  
  echo "Downloaded artifacts: $(find ${working_directory}/${download_dir_name} -type f | wc -l)" | tee -a ${out_file}
  find ${working_directory}/${download_dir_name} | tee -a ${out_file}
}

function clone_repo() {
  echo "### clone_repo $@"
  local working_directory repository target_git_tag checkout_directory base_git_tag

  if [[ "$#" != 5 ]]; then
    echo "Usage: <working-directory> <repository> <target-git-tag> <checkout-directory> <base-git-tag>"
    return 1
  fi

  working_directory=$1
  repository=$2
  target_git_tag=$3
  checkout_directory=$4
  base_git_tag=$5

  local out_file
  out_file=${working_directory}/git-clone.out
  git clone --branch ${target_git_tag} git@github.com:apache/${repository}.git ${checkout_directory} 2>&1 | tee ${out_file}
  cd ${checkout_directory}
  git fetch origin ${base_git_tag} 2>&1 | tee -a ${out_file}
}

function extract_source_artifacts() {
  echo "### extract_source_artifacts $@"
  local working_directory download_directory source_directory repository_name version
  
  if [[ "$#" != 5 ]]; then
    echo "Usage: <working-directory> <download-directory> <source-directory> <repository-name> <version>"
    return 1
  fi

  working_directory=$1
  download_directory=$2
  source_directory=$3
  repository_name=$4
  version=$5

  # extracts downloaded sources
  mkdir -p $source_directory
  tar -xzf ${download_directory}/*src.tgz --directory ${source_directory}

  # remove this extra layer in the directory structure
  mv ${source_directory}/${repository_name}-${version}/* ${source_directory}
  # try to move hidden files as well
  if [[ $(ls ${source_directory}/${repository_name}-${version}/.[^.]* | wc -l) != 0 ]]; then
    mv ${source_directory}/${repository_name}-${version}/.[^.]* ${source_directory}
  fi

  rm -d ${source_directory}/${repository_name}-${version}
}
