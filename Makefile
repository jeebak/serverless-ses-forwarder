# These version values for node/npm are used
NPM_VERSION="6.13.4"

SHELL = /bin/bash

deploy: config-exists npm-install is-aws-available
	@./scripts/aws.bash deploy

remove: config-exists npm-install is-aws-available
	@./scripts/aws.bash remove

npm-install: is-npm-available
	@npm install
	@npm install -g npm@"$(NPM_VERSION)"

is-npm-available:
	@command -v npm > /dev/null

is-aws-available:
	@command -v aws > /dev/null

config-exists:
	@[[ -e config.yml ]]
