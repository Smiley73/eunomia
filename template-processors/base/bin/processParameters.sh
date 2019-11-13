#!/usr/bin/env bash

# Copyright 2019 Kohl's Department Stores, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -o nounset
set -o errexit

echo "Processing Parameters"

FOLDERS=""

if [ -e ${CLONED_PARAMETER_GIT_DIR}/hiera.lst ] ; then
  echo "Generating hierarchy"
  # a hierarchy list was provided, so lets process it
  envsubst < ${CLONED_PARAMETER_GIT_DIR}/hiera.lst | while read -r DIR
    do
      # remove everything after # to allow comments and nuke all whitespaces
      DIR="$(echo -e "${DIR%%#*}}" | tr -d '[:space:]')"

      # add the folder to the end of the list
      FOLDERS="${FOLDERS} ${CLONED_PARAMETER_GIT_DIR}/${DIR}"
    done
    
fi

# Add the current folder as the last one to process
FOLDERS="${FOLDERS} ${CLONED_PARAMETER_GIT_DIR}"

echo "Going to process parameters file in the following folder(s): ${FOLDERS}"

VALUES_FILE=${CLONED_PARAMETER_GIT_DIR}/eunomia_values_processed1.yaml

for DIR in ${FOLDERS}; do
  echo "Processing files in ${DIR}"
  
  # get the list of yaml files to process
  YAML_FILES="$(find ${DIR} -name \*.json -o -name \*.yaml -o -name \*.yml  -depth 1)"
  
  # ensure our base file exists
  touch ${VALUES_FILE}

  # merge the files
  goyq merge --inplace ${VALUES_FILE} ${YAML_FILES}
done

# Replace variables from enviroment
# This allows determining things like cluster names, regions, etc.
if [ -e ${VALUES_FILE} ]; then
  envsubst < ${VALUES_FILE} > $CLONED_PARAMETER_GIT_DIR/eunomia_values_processed.yaml
else
  echo "ERROR - missing parameter files"
  exit 1
fi
