export N_PREFIX := $(HOME)/n
export PATH := $(N_PREFIX)/bin:$(PATH)
# These version values for node/npm are used
NODE_VERSION="8.11.3"
NPM_VERSION="6.9.0"

SHELL = /bin/bash

deploy: config-exists npm-install is-aws-available
	@./scripts/aws.bash deploy

remove: config-exists npm-install is-aws-available
	@./scripts/aws.bash remove

npm-install: is-npm-available
	@npm install
	@./node_modules/.bin/n "$(NODE_VERSION)"
	@npm install -g npm@"$(NPM_VERSION)"

is-npm-available:
	@command -v npm > /dev/null

is-aws-available:
	@command -v aws > /dev/null

config-exists:
	@[[ -e config.yml ]]
