SHELL = /bin/bash

deploy: npm-install is-aws-available
	@./scripts/aws.bash deploy

remove: npm-install is-aws-available
	@./scripts/aws.bash remove

npm-install: is-npm-available
	@npm install

is-npm-available:
	@command -v npm > /dev/null

is-aws-available:
	@command -v aws > /dev/null
