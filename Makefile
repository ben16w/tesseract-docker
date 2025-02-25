SHELL := /bin/bash

# Variables for Ansible.
TAGS ?= all
LIM ?= all
DEPLOY ?= prod
COMMAND ?=

# Variables for Molecule.
ROLE ?=
SCENARIO ?= default
CMD ?= test
DESTROY ?= always
HOST ?=

# Variables for SSH.
SSH_USER ?= vagrant
SSH_HOST ?= localhost
SSH_KEY ?= ~/.vagrant.d/insecure_private_key

# Variables for link-collections.
COLLECTIONS_PATH ?= .
PROJECT_PATH ?= ../
NAME_SUFFIX ?= roles-

# Help target to display available targets and their descriptions.
.PHONY: help
help:
	@echo "Provides a set of targets to help with the development and testing of Tesseract Ansible projects."
	@echo ""
	@echo "Available targets:"
	@echo "  help                 - Display this help message"
	@echo "  install              - Install Ansible Galaxy roles"
	@echo "  install-venv         - Create a virtual environment and install Python packages."
	@echo "  lint                 - Lint the repository."
	@echo "  update-requirements  - Update the commit hash in the ansible requirements.yml file to the current commit hash."
	@echo "  update-molecule      - Overwrite all molecule.yml files in roles from the molecule.yml in the repository root."
	@echo "  link-collections     - Link the local repository Ansible collections to the Ansible collections directory"
	@echo "                         Usage: make link-collections COLLECTIONS_PATH=<path> PROJECT_PATH=<path> NAME_SUFFIX=<suffix>"
	@echo "  delete-vms           - Stop and delete all VirtualBox VMs"
	@echo "  test                 - Run test for a role directory or the root directory using molecule."
	@echo "                         Usage: make test ROLE=<role> SCENARIO=<scenario> CMD=<command> DESTROY=<always|never> HOST=<host>"
	@echo "  test-changed         - Run all tests for a roles which have been modified since the last commit using molecule."
	@echo "                         Usage: make test-all-distros SCENARIO=<scenario>"
	@echo "  test-all             - Run all tests for all roles in the repository using molecule."
	@echo "                         Usage: make test-all-distros SCENARIO=<scenario>"
	@echo "  test-all-distros     - Run all tests for all roles in the repository using molecule on a specific distros."
	@echo "                         Usage: make test-all-distros SCENARIO=<scenario>"
	@echo "  ssh                  - SSH to a specific host"
	@echo "                         Usage: make ssh SSH_USER=<user> SSH_HOST=<host> SSH_KEY=<key>"
	@echo "  vault                - Edit the ansible vault"
	@echo "                         Usage: make vault DEPLOY=<deploy>"
	@echo "  check                - Check the playbook"
	@echo "                         Usage: make check LIM=<limit> DEPLOY=<deploy>"
	@echo "  command              - Execute a specific Ansible ad-hoc command"
	@echo "                         Usage: make ansible LIM=<limit> DEPLOY=<deploy> COMMAND='<command>'"
	@echo "  shutdown             - Shutdown all hosts"
	@echo "                         Usage: make shutdown LIM=<limit> DEPLOY=<deploy>"
	@echo "  deploy               - Deploy the playbook with specified tags"
	@echo "                         Usage: make deploy TAGS=<tag1>,<tag2> LIM=<limit> DEPLOY=<deploy>"
	@echo ""

# Define directive to activate the virtual environment.
define activate-venv
	set -e ;\
	if [ -d .venv ]; then \
		source .venv/bin/activate ;\
	else \
		echo "ERROR: No virtual environment found, run 'make install-venv' first." ;\
		exit 1 ;\
	fi
endef

# Define directive to run a molecule test for a role directory.
define molecule-test
	set -e ;\
	if [ -f $${moleculedir}/default/molecule.yml ]; then \
		pushd $$(dirname $${moleculedir}) > /dev/null ;\
		if [ "$(CMD)" == "test" ]; then \
			if [ "$(DESTROY)" == "always" ]; then \
				molecule test --scenario-name $(SCENARIO) --destroy always ;\
			else \
				molecule test --scenario-name $(SCENARIO) --destroy never ;\
			fi ;\
		elif [ "$(CMD)" == "login" ]; then \
			if [ "$(HOST)" == "" ]; then \
				molecule login --scenario-name $(SCENARIO) ;\
			else \
				molecule login --scenario-name $(SCENARIO) -h $(HOST) ;\
			fi ;\
		else \
			molecule $(CMD) --scenario-name $(SCENARIO) ;\
		fi ;\
		popd > /dev/null ;\
	else \
		echo "No molecule.yml found for role: $${moleculedir}" ;\
	fi
endef

# Define directive to run a molecule test for a role directory when multiple tests are required.
define molecule-test-multi
	set -e ;\
	if [ -f $${moleculedir}/default/molecule.yml ]; then \
		pushd $$(dirname $${moleculedir}) ;\
		export INSTANCE_NAME=$$(echo "molecule-$$RANDOM") ;\
		molecule test ;\
		popd ;\
	else \
		echo "No molecule.yml found for role: $${moleculedir}" ;\
	fi
endef

.PHONY: install
install:
	@set -e ;\
	$(activate-venv) ;\
	ansible-galaxy install -r requirements.yml

.PHONY: install-venv
install-venv:
	@set -e ;\
	if [ ! -d .venv ]; then \
		python3 -m venv .venv ;\
	fi ;\
	$(activate-venv) ;\
	if sudo -n true 2>/dev/null; then \
		sudo chown -R $(shell stat -c "%U:%G" .) .venv ;\
	else \
		for file in $$(find .venv -type f); do \
			if ! chown $(shell stat -c "%U:%G" .) "$$file" 2>/dev/null; then \
				echo "ERROR: Failed to change virtual environment owner." ;\
				exit 1 ;\
			fi ;\
		done ;\
	fi ;\
	pip install -q --upgrade -r requirements.txt ;\
	echo "Run 'source .venv/bin/activate' to activate the virtual environment."

.PHONY: lint
lint:
	@set -e ;\
	$(activate-venv) ;\
	echo "Linting Docker Compose files...." ;\
	for file in $$(find . -type f -name 'docker-compose.*.yml' \
		! -path "./.venv/*" \
		! -path "./.ansible/*" \
		! -path "./ansible_collections/*" \
		) ; do \
		docker compose -f "$$file" config --quiet ;\
	done ;\
	echo "Linting shell scripts...." ;\
	for file in $$(find . -type f -name '*.sh' \
		! -path "./.venv/*" \
		! -path "./.ansible/*" \
		! -path "./ansible_collections/*" \
		) ; do \
		shellcheck -S warning "$$file" ;\
	done ;\
	echo "Linting YAML files...." ;\
	find . -type f \
		\( -name "*.yml" -o -name "*.yaml" \) \
		! -path "./.venv/*" \
		! -path "./.ansible/*" \
		! -path "./ansible_collections/*" \
		-print | xargs yamllint -d relaxed ;\
	echo "Linting Ansible files...." ;\
	if [[ -f "ansible.cfg" \
		|| -d "roles" \
		|| -d "playbooks" \
		|| -d "group_vars" \
		|| -d "host_vars" ]]; then \
		ANSIBLE_ASK_VAULT_PASS=false ansible-lint \
			--exclude "ansible_collections/" "playbooks/" "docker-compose.*.yml" \
			-w var-naming[no-role-prefix] \
			--offline -q ;\
	fi ;\
	echo "Success!"

.PHONY: update-requirements
update-requirements:
	@set -e ;\
	COMMITS=$$(grep -E "version:" requirements.yml | cut -d ":" -f 2 | tr -d ' ') ;\
	REPOS=$$(grep -E "name:" requirements.yml | grep "tesseract" | cut -d ":" -f 2,3 | tr -d ' ') ;\
	COUNTER=1 ;\
	for COMMIT in $${COMMITS}; do \
		TMP_DIR=$$(mktemp -d) ;\
		pushd $$TMP_DIR ;\
		echo "Cloning $$(echo $${REPOS} | cut -d ' ' -f $${COUNTER})" ;\
		git clone $$(echo $${REPOS} | cut -d ' ' -f $${COUNTER}) . ;\
		NEW_COMMIT=$$(git rev-parse HEAD) ;\
		echo "Replacing $${COMMIT} with $${NEW_COMMIT}" ;\
		popd ;\
		sed -i "s/$${COMMIT}/$${NEW_COMMIT}/g" requirements.yml ;\
		rm -rf $$TMP_DIR ;\
		COUNTER=$$[$$COUNTER +1] ;\
	done ;\
	echo "Success!"

.PHONY: update-molecule
update-molecule:
	@set -e ;\
	if [ ! -f molecule.yml ]; then \
		echo "ERROR: No molecule.yml found in repository root" ;\
		exit 1 ;\
	fi ;\
	for moleculedir in roles/*/molecule; do \
		echo "Updating molecule.yml for role: $${moleculedir}" ;\
		if [ ! -f $${moleculedir}/default/molecule.yml ]; then \
			echo "ERROR: No molecule.yml found for role: $${moleculedir}" ;\
			exit 1 ;\
		fi ;\
		if cmp -s molecule.yml $${moleculedir}/default/molecule.yml; then \
			echo "WARNING: $${moleculedir}/default/molecule.yml equals molecule.yml in repository root, skipping." ;\
		else \
			cp molecule.yml $${moleculedir}/default/molecule.yml ;\
		fi ;\
	done ;\
	echo "Success!"

.PHONY: link-collections
link-collections:
	@set -e ;\
	for COLLECTION in $$(ls -d $(COLLECTIONS_PATH)/ansible_collections/tesseract/* ); do \
		COLLECTION_NAME=$$(basename $${COLLECTION}) ;\
		REAL_PROJECT_PATH=$$(realpath $(PROJECT_PATH)) ;\
		echo "Linking $${COLLECTION} to $${REAL_PROJECT_PATH}/$(NAME_SUFFIX)$${COLLECTION_NAME}" ;\
		if [ ! -d "$${REAL_PROJECT_PATH}/$(NAME_SUFFIX)$${COLLECTION_NAME}" ]; then \
			echo "ERROR: The project path does not exist." ;\
			exit 1 ;\
		fi ;\
		rm -rf $${COLLECTION} ;\
		ln -s $${REAL_PROJECT_PATH}/$(NAME_SUFFIX)$${COLLECTION_NAME} $${COLLECTION} ;\
	done ;\
	echo "Success!"

.PHONY: delete-vms
delete-vms:
	@set -e ;\
	VBoxManage list runningvms | awk '{print $$2}' | xargs -I{} VBoxManage controlvm {} poweroff ;\
	VBoxManage list vms | awk '{print $$2}' | xargs -I{} VBoxManage unregistervm {} ;\
	rm -rf ~/VirtualBox\ VMs/*

.PHONY: test
test:
	@set -e ;\
	$(activate-venv) ;\
	if [ "$(ROLE)" == "" ]; then \
		moleculedir="./molecule" ;\
	else \
		moleculedir="roles/$(ROLE)/molecule" ;\
	fi ;\
	if [ ! -f $${moleculedir}/$(SCENARIO)/molecule.yml ]; then \
		echo "No molecule.yml found for role: $${moleculedir}" ;\
		exit 1 ;\
	fi ;\
	echo "Testing role: $${moleculedir}" ;\
	$(molecule-test) ;\
	echo "Success!"

.PHONY: test-changed
test-changed:
	@set -e ;\
	$(activate-venv) ;\
	git fetch origin main ;\
	roles="$$((git diff --name-only $$(git merge-base HEAD origin/main); git diff --name-only;) | grep "roles/" | cut -d '/' -f 1-2 | sort -u )" ;\
	for roledir in $${roles}; do \
		moleculedir="$${roledir}/molecule" ;\
		echo "Testing role: $${moleculedir}" ;\
		$(molecule-test-multi) ;\
	done ;\
	echo "Success!"

.PHONY: test-all
test-all:
	@set -e ;\
	$(activate-venv) ;\
	for moleculedir in roles/*/molecule; do \
		echo "Testing role: $${moleculedir}" ;\
		$(molecule-test-multi) ;\
	done ;\
	echo "Success!"

.PHONY: test-all-distros
test-all-distros:
	@set -e ;\
	$(activate-venv) ;\
	if [ -z "$$DISTRO_LIST" ]; then \
		echo "ERROR: DISTRO_LIST environment variable is not defined." ;\
		exit 1 ;\
	fi ;\
	for moleculedir in roles/*/molecule; do \
		for distro in $(shell echo $$DISTRO_LIST); do \
			echo "Testing role: $${moleculedir} on $${distro}" ;\
			export MOLECULE_DISTRO=$${distro} ;\
			$(molecule-test-multi) ;\
		done ;\
	done ;\
	echo "Success!"

.PHONY: ssh
ssh:
	@set -e ;\
	echo "SSH to $(SSH_USER)@$(SSH_HOST)" ;\
	ssh -i "$(SSH_KEY)" "-o StrictHostKeyChecking=no" $(SSH_USER)@$(SSH_HOST)

.PHONY: vault
vault:
	@set -e ;\
	$(activate-venv) ;\
	ansible-vault edit inventories/$(DEPLOY)/group_vars/all.yml

.PHONY: check
check:
	@set -e ;\
	$(activate-venv) ;\
	ansible-playbook -i inventories/$(DEPLOY)/hosts.yml playbooks/$(DEPLOY).yml --limit $(LIM) --diff --check

.PHONY: command
command:
	@set -e ;\
	$(activate-venv) ;\
	if [ "$(COMMAND)" == "" ]; then \
		echo "ERROR: COMMAND variable is not defined." ;\
		exit 1 ;\
	fi ;\
	ansible -i inventories/$(DEPLOY)/hosts.yml all -m shell -a "$(CMD)" --limit $(LIM)

.PHONY: shutdown
shutdown:
	@set -e ;\
	$(activate-venv) ;\
	ansible -i inventories/$(DEPLOY)/hosts.yml all -b -m shell -a "shutdown -h now" --limit $(LIM)

.PHONY: deploy
deploy:
	@set -e ;\
	$(activate-venv) ;\
	ansible-playbook -i inventories/$(DEPLOY)/hosts.yml playbooks/$(DEPLOY).yml --tags $(TAGS) --limit $(LIM)
