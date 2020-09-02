#!/bin/bash
# Copyright 2020 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

path_from_yaml() {
    python3 -c "from ruamel.yaml import YAML;\
      yaml=YAML();\
      c=yaml.load(open('galaxy.yml.in'));\
      print('%s/%s'%(c['namespace'],c['name']))"
}

TOXDIR=${1:-.}

# Detect collection namespace and name from galaxy.yml.in
collection_path=$(path_from_yaml)
ANSIBLE_COLLECTIONS_PATH=$(mktemp -d)/ansible_collections/${collection_path}
echo "Executing ansible-test sanity checks in ${ANSIBLE_COLLECTIONS_PATH}"

trap "rm -rf ${ANSIBLE_COLLECTIONS_PATH}" err exit

rm -rf "${ANSIBLE_COLLECTIONS_PATH}"
mkdir -p ${ANSIBLE_COLLECTIONS_PATH}

# Created collection x.y at z
#output=$(ansible-galaxy collection build --force | sed 's,.* at ,,')
#location=$(ansible-galaxy collection install ${output} \
#  -p ${ANSIBLE_COLLECTIONS_PATH} --force)
#for folder in ${TOXDIR}/{docs,playbooks,plugins,roles,tests}; do
#  if [ -d $folder ]; then
#    cp -av $folder ${ANSIBLE_COLLECTIONS_PATH}/$folder;
#  fi
#done
#ls -al $ANSIBLE_COLLECTIONS_PATH
cp -av ${TOXDIR}/{plugins,docs,plugins,roles,tests} \
  ${ANSIBLE_COLLECTIONS_PATH} || true
cp ${TOXDIR}/galaxy.yml ${ANSIBLE_COLLECTIONS_PATH}
cd ${ANSIBLE_COLLECTIONS_PATH}
mkdir ${ANSIBLE_COLLECTIONS_PATH}/logs
echo "Running ansible-test with version:"
ansible --version
echo $(tree `pwd`)
ansible-test sanity \
    --venv --python 3.8 --debug -v \
    --skip-test metaclass-boilerplate \
    --skip-test future-import-boilerplate

