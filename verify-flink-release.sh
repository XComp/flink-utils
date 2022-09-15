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

# defaults
maven_exec="mvn"
working_dir="$(pwd)"

print_usage() {
  echo "Usage: $0 [-h] [-d] -u <url> -g <gpg-public-key-ref> [-m <maven-exec>] [-w <working-directory>] [-s <source-directory>]"
  echo ""
  echo "  -h            Prints information about this script."
  echo "  -d            Enables debug logging."
  echo "  -u            URL that's used for downloaded the artifacts."
  echo "  -g            GPG public key reference that was used for signing the artifacts."
  echo "  -m            Maven executable being used. Only Maven 3.2.5 is supported for now. (default: $maven_exec)"
  echo "  -w            Working directory used for downloading and processing the artifacts. The directory needs to exist beforehand. (default: $working_dir)"
  echo "  -s            Source directory is the folder where the source are extracted to. (default: <working-directory>/<flink-version-tag>/src)"
}

print_info_and_exit() {
  echo "$0 verifies Flink releases. The following steps are executed:"
  echo "  - Download all resources"
  echo "  - Extracts sources and runs build"
  echo "  - Verifies SHA512 checksums"
  echo "  - Verifies GPG certifaction"
  echo "  - Checks that all POMs have the right expected version"
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

if [[ "$#" == 0 ]]; then
  print_info_and_exit
fi

while getopts "hdm:u:g:w:s:" o; do
  case "${o}" in
    d)
      set -x
      ;;
    h)
      print_info_and_exit
      ;;
    u)
      # remove any trailing slashes from url
      url=${OPTARG%/}
      ;;
    g)
      public_gpg_key=${OPTARG}
      ;;
    m)
      maven_exec=${OPTARG}
      ;;
    w)
      working_dir=${OPTARG}
      if [[ ! -d ${working_dir} ]]; then
        print_error_with_usage_and_exit "Passed working directory ${working_dir} doesn't exist."
      fi
      ;;
    s)
      source_directory=${OPTARG}
      ;;
    *)
      print_error_with_usage_and_exit "Invalid parameter passed: ${o}"
      ;;
  esac
done

# check required variables
if [[ -z "${url+x}"  ]]; then
  print_error_with_usage_and_exit "Missing URL"
elif [[ -z "${public_gpg_key+x}" ]]; then
  print_error_with_usage_and_exit "Missing GPG public key reference"
fi

# derive variables
flink_git_tag="$(echo $url | grep -o '[^/]*$')"
flink_version="$(echo $flink_git_tag | sed 's/\(.*\)-rc[0-9]\+/\1/g')"
if [[ -z "${source_directory+x}" ]]; then
  # derive source directory if it isn't specified
  source_directory="$working_dir/$flink_git_tag/src"
fi

# validate variables
if ! which $maven_exec &> /dev/null; then
  echo "Error: Maven executable '${maven_exec}' not found."
  exit 1
elif ! grep --quiet "Apache Maven 3.2.5" <($maven_exec --version); then
  echo "Error: Wrong Maven version used. Only 3.2.5 is supported."
  $maven_exec --version
  exit 1
fi

echo "GPG verification happens for:"
gpg --list-keys ${public_gpg_key}

if [[ "$(gpg --list-keys | grep -c $public_gpg_key)" == "0" ]]; then
  gpg_key_server="pgpkeys.mit.edu"
  echo "The key $public_gpg_key wasn't found in the local registry. Trying to load it from $gpg_key_server."
  gpg --keyserver $gpg_key_server --recv-key ${public_gpg_key}
fi

# download and extract sources
wget --recursive --no-parent --directory-prefix ${working_dir} --reject "*.html,*.tmp,*.txt" "${url}/"
mv ${working_dir}/dist.apache.org/repos/dist/dev/flink/flink* ${working_dir}
rm -rf ${working_dir}/dist.apache.org

mkdir -p $source_directory
tar -xzf ${working_dir}/${flink_git_tag}/*src.tgz --directory ${source_directory}
cd ${source_directory}/flink*
$maven_exec -T1C -DskipTests -pl flink-dist -am package 2>&1 | tee ${working_dir}/source-build.out
cd -

gpg_checksum_file=${working_dir}/gpg.out
sha_checksum_file=${working_dir}/sha.out
for f in $(find ${flink_git_tag} \( -path ${source_directory#"${working_dir}/"} -prune -or -not -name "*sha512" -and -not -name "*asc" \) -and -type f); do
  sha512_checksum_of_file="$(sha512sum $f | grep -o "^[^ ]*")"
  downloaded_sha512_checksum="$(cat $f.sha512 | grep -o "^[^ ]*")"

  echo "$f"
  echo "$f" >> ${gpg_checksum_file}
  echo "$f" >> ${sha_checksum_file}
  if [[ "${sha512_checksum_of_file}" == "${downloaded_sha512_checksum}" ]]; then
    echo -e "   <SHA512> [\e[32mCORRECT\e[0m]" | tee -a ${sha_checksum_file}
  else
    echo -e "   <SHA512> [\e[31mERROR\e[0m]" | tee -a ${sha_checksum_file}
    echo    "   $f.sha512 does not match the checksum of $f" | tee -a ${sha_checksum_file}
    exit 1
  fi

  if $(gpg --verify $f.asc $f &> /dev/null); then
    echo -e "   <GPG>    [\e[32mCORRECT\e[0m]" | tee -a ${gpg_checksum_file}
  else
    echo -e "   <GPG>    [\e[31mERROR\e[0m]" | tee -a ${gpg_checksum_file}
    echo    "   $f.asc does not match the GPG key $f is certified with" | tee -a ${gpg_checksum_file}
    exit 1
  fi
done

# TODO: We should filter the parent pom to remove the Apache projects version from the output
pom_version_check_file=${working_dir}/pom-version-check.out
echo "Checking the version with the pom files (no version should show up except for the Apache version):" | tee -a ${pom_version_check_file}
find ${source_directory} -name pom.xml -not -path "*target*" -exec sh -c "grep -A3 '<parent>' {} | grep version | sed 's/.*<version>\([^<]*\)<\/version>.*/\1/g'" \; | grep -v $flink_version | sort | uniq -c | tee -a ${pom_version_check_file}
