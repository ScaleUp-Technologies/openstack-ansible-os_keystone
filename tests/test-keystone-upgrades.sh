#!/usr/bin/env bash

# Copyright 2016, Rackspace US, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# WARNING:
# This file is use by all OpenStack-Ansible roles for testing purposes.
# Any changes here will affect all OpenStack-Ansible role repositories
# with immediate effect.

# PURPOSE:
# This script executes test Ansible playbooks required for performing
# an upgrade test of the os_neutron role.
# Due to the way Ansible caches and handles modules, we need to run
# separate Ansible runs to ensure the "upgrade" uses the new
# "neutron_migrations_facts" module, instead of the cached version
# used when deploying the previous Neutron version.

## Shell Opts ----------------------------------------------------------------

set -e

## Vars ----------------------------------------------------------------------

export WORKING_DIR=${WORKING_DIR:-$(pwd)}
export ROLE_NAME=${ROLE_NAME:-''}

export ANSIBLE_PARAMETERS=${ANSIBLE_PARAMETERS:-"-vv"}
export TEST_PLAYBOOK=${TEST_PLAYBOOK:-$WORKING_DIR/tests/test-upgrade-pre.yml}
export TEST_CHECK_MODE=${TEST_CHECK_MODE:-false}
export TEST_IDEMPOTENCE=${TEST_IDEMPOTENCE:-false}
export COMMON_TESTS_PATH="${WORKING_DIR}/tests/common"

echo "ANSIBLE_OVERRIDES: ${ANSIBLE_OVERRIDES}"
echo "ANSIBLE_PARAMETERS: ${ANSIBLE_PARAMETERS}"
echo "TEST_PLAYBOOK: ${TEST_PLAYBOOK}"
echo "TEST_CHECK_MODE: ${TEST_CHECK_MODE}"
echo "TEST_IDEMPOTENCE: ${TEST_IDEMPOTENCE}"

## Functions -----------------------------------------------------------------

function execute_ansible_playbook {

  export ANSIBLE_CLI_PARAMETERS="${ANSIBLE_PARAMETERS} -e @${ANSIBLE_OVERRIDES}"
  export ANSIBLE_BIN=${ANSIBLE_BIN:-"ansible-playbook"}
  CMD_TO_EXECUTE="${ANSIBLE_BIN} ${TEST_PLAYBOOK} $@ ${ANSIBLE_CLI_PARAMETERS}"

  echo "Executing: ${CMD_TO_EXECUTE}"
  echo "With:"
  echo "    ANSIBLE_INVENTORY: ${ANSIBLE_INVENTORY}"
  echo "    ANSIBLE_LOG_PATH: ${ANSIBLE_LOG_PATH}"

  ${CMD_TO_EXECUTE}

}

## Main ----------------------------------------------------------------------

# Ensure that the Ansible environment is properly prepared
source "${COMMON_TESTS_PATH}/test-ansible-env-prep.sh"

# Prepare environment for the initial deploy of (previous and current) Keystone
# No upgrading or testing is done yet.
export TEST_PLAYBOOK="${WORKING_DIR}/tests/test-upgrade-pre.yml"
export ANSIBLE_LOG_PATH="${ANSIBLE_LOG_DIR}/ansible-execute-keystone-infrainstall.log"

# Execute the setup of the Keystone environment
execute_ansible_playbook

# Prepare environment for the deploy of previous Keystone:
# No upgrading or testing is done yet.
export TEST_PLAYBOOK="${WORKING_DIR}/tests/test-install-previous-keystone.yml"
export ANSIBLE_LOG_PATH="${ANSIBLE_LOG_DIR}/ansible-execute-previous_keystone-install.log"
export PREVIOUS_VENV="ansible-previous"
export ANSIBLE_BIN="${WORKING_DIR}/.tox/${PREVIOUS_VENV}/bin/ansible-playbook"
source ${COMMON_TESTS_PATH}/test-create-previous-venv.sh

# Execute the setup of previous Keystone
execute_ansible_playbook

# Unset previous branch overrides
unset PREVIOUS_VENV
unset ANSIBLE_BIN

# Prepare environment for the upgrade of Keystone
export TEST_PLAYBOOK="${WORKING_DIR}/tests/test-upgrade-post.yml"
export ANSIBLE_LOG_PATH="${ANSIBLE_LOG_DIR}/ansible-execute-keystone-upgrade.log"

# Excute the upgrade of Keystone including testing/benchmarking
execute_ansible_playbook
