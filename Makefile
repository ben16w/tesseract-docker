# Lint all roles in the repository using yamllint.
.PHONY: lint
lint:
	@set -e ;\
	yamllint -d relaxed . ;\
	for file in $$(find . -type f -name 'docker-compose.*.yml') ; do \
		docker compose -f $$file config --quiet ;\
	done ;\
	echo "Success!"


