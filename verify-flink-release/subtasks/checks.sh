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

function check_gpg() {
  local working_directory public_gpg_key download_directory gpg_key_server gpg_checksum_file

  if [[ "$#" != 3 ]] && [[ "$#" != 4 ]]; then
    echo "Usage: <working-directory> <public-gpg-key> <download_directory> [<gpg_key_server>]"
    return 1
  fi

  working_directory=$1
  public_gpg_key=$2
  download_directory=$3
  gpg_key_server=${4:-"pgpkeys.mit.edu"}
  gpg_checksum_file=${working_directory}/gpg.out
  
  echo "GPG verification happens for:" | tee ${gpg_checksum_file}
  gpg --list-keys ${public_gpg_key} | tee -a ${gpg_checksum_file}

  if [[ "$(gpg --list-keys | grep -c $public_gpg_key)" == "0" ]]; then
    echo "The key $public_gpg_key wasn't found in the local registry. Trying to load it from $gpg_key_server." | tee -a ${gpg_checksum_file}
    gpg --keyserver $gpg_key_server --recv-key ${public_gpg_key} | tee -a ${gpg_checksum_file}
  fi

  for f in $(find ${download_directory} -not -name "*sha512" -and -not -name "*asc" -and -type f); do
    echo "$f"
    echo "$f" >> ${gpg_checksum_file}
    if $(gpg --verify $f.asc $f &> /dev/null); then
      echo -e "   <GPG>    [\e[32mCORRECT\e[0m]" | tee -a ${gpg_checksum_file}
    else
      echo -e "   <GPG>    [\e[31mERROR\e[0m]" | tee -a ${gpg_checksum_file}
      echo    "   $f.asc does not match the GPG key $f is certified with" | tee -a ${gpg_checksum_file}
      return 1
    fi
  done
}

function check_sha512() {
  local working_directory download_directory sha_checksum_file sha512_checksum_of_file downloaded_sha512_checksum

  if [[ "$#" != 2 ]]; then
    echo "Usage: <working-directory> <download_directory>"
    return 1
  fi

  working_directory=$1
  download_directory=$2
  sha_checksum_file=${working_directory}/sha.out
  
  for f in $(find ${download_directory} -not -name "*sha512" -and -not -name "*asc" -and -type f); do
    sha512_checksum_of_file="$(sha512sum $f | grep -o "^[^ ]*")"
    downloaded_sha512_checksum="$(cat $f.sha512 | grep -o "^[^ ]*")"

    echo "$f"
    echo "$f" >> ${sha_checksum_file}
    if [[ "${sha512_checksum_of_file}" == "${downloaded_sha512_checksum}" ]]; then
      echo -e "   <SHA512> [\e[32mCORRECT\e[0m]" | tee -a ${sha_checksum_file}
    else
      echo -e "   <SHA512> [\e[31mERROR\e[0m]" | tee -a ${sha_checksum_file}
      echo    "   $f.sha512 does not match the checksum of $f" | tee -a ${sha_checksum_file}
      return 1
    fi
  done
}

function compare_downloaded_source_with_repo_checkout() {
  local working_directory checkout_directory source_directory

  if [[ "$#" != 3 ]]; then
    echo "Usage: <working-directory> <checkout_directory> <source_directory>"
    return 1
  fi

  working_directory=$1
  checkout_directory=$2
  source_directory=$3

  comm -3 \
    <(find ${checkout_directory} -type f | sed "s~${checkout_directory}/~~g" | sort) \
    <(find ${source_directory} -type f | sed "s~${source_directory}/~~g" | sort) \
      | tee ${working_directory}/diff-download-clone.out
}

function check_version_in_poms() {
  local working_directory source_directory flink_version

  if [[ "$#" != 3 ]]; then
    echo "Usage: <working-directory> <source_directory> <flink_version>"
    return 1
  fi

  working_directory=$1
  source_directory=$2
  flink_version=$3
  pom_version_check_file=${working_directory}/pom-version-check.out

  # TODO: We should filter the parent pom to remove the Apache projects version from the output
  echo "Checking the version with the pom files (no version should show up except for the Apache version):" | tee -a ${pom_version_check_file}
  find ${source_directory} -name pom.xml -not -path "*target*" \
    -exec sh -c "grep -A3 '<parent>' {} | grep version | sed 's/.*<version>\([^<]*\)<\/version>.*/\1/g'" \; | \
      grep -v $flink_version | \
      sort | \
      uniq -c | tee -a ${pom_version_check_file}
}
