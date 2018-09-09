SHELL = /bin/bash

deploy: config-exists npm-install is-aws-available
	@./scripts/aws.bash deploy

remove: config-exists npm-install is-aws-available
	@./scripts/aws.bash remove

npm-install: is-npm-available
	@npm install

is-npm-available:
	@command -v npm > /dev/null

is-aws-available:
	@command -v aws > /dev/null

config-exists:
	@[[ -e config.yml ]]
