# serverless-aws-lambda-ses-forwarder

A [Serverless](https://serverless.com) Service for setting up an email
forwarding app

using [AWS Simple Email Service](https://aws.amazon.com/ses/) and Lambda. You
can configure the service to forward by email address, as well as by
domain/wildcard/catchall.

Under the hood, this app uses arithmetric's fantastic
[aws-lambda-ses-forwarder](https://github.com/arithmetric/aws-lambda-ses-forwarder).

# Work In Progress

## Getting started

## Install Serverless and provision AWS

1. Setup your [AWS Credentials](https://github.com/serverless/serverless/blob/master/docs/providers/aws/guide/credentials.md)

1. Install this Service

  ```
  git clone https://github.com/jeebak/serverless-ses-forwarder
  cd serverless-ses-forwarder
  make npm-install
  ```

1. Configure the Lambda Function

  ```
  cp config.yml.example config.yml
  ```

  Then edit `config.yml`. This file contains the rules for forwarding emails,
  as well as more fine grained options. It directly maps to the config object
  in [aws-lambda-ses-forwarder](https://github.com/arithmetric/aws-lambda-ses-forwarder), so
  see that project for all the available options.

  **NOTE:** that `config.yml` is in `.gitignore`. It is your responsibility to
  keep it out of a publicly accessibly repo (unless you don't care if your
  forwarding emails are public) and to keep a backup copy of it for safe
  keeping.

1. Deploy it

   ````
   make deploy
   ````

1. Configure SES

   Once the stack is stood up, you will need to set-up AWS SES to route
   incoming emails to your Lambda function. Regretfully, this is a manual step
   until such time as Amazon provides CloudFormation support for SES.

   Follow steps 3-6 in the [aws-lambda-ses-forwarder
   README](https://github.com/arithmetric/aws-lambda-ses-forwarder/blob/master/README.md).
