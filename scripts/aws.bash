#!/usr/bin/env bash

errcho() {
  # echo to strerr
  >&2 echo "$@"
}

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$CURRENT_DIR" || exit

AWS_DEFAULT_OUTPUT="text"
AWS_DEFAULT_REGION="$(
  cd .. \
    && "$(npm bin)/js-yaml" config.yml | "$(npm bin)/underscore" --outfmt text extract 'config.aws_region'  2> /dev/null \
    || echo us-east-1
)"
AWS_PROFILE="$(
  cd .. \
    && "$(npm bin)/js-yaml" config.yml | "$(npm bin)/underscore" --outfmt text extract 'config.aws_profile' 2> /dev/null \
    || echo default
)"
AWS_ACCOUNT_ID="$(
  aws --profile "$AWS_PROFILE" --region "$AWS_DEFAULT_REGION" \
    sts get-caller-identity \
      --query "Account" --output text
)"
AWS_SES_RULE_SET_NAME="ses-forwarder-rule-set"
AWS_SES_RULE_NAME="ses-forwarder-rule"
AWS_SES_RULE_FILE="file://$PWD/../data/ses-forwarder-rule.json"

BUCKET_NAME="sesforwarder-${AWS_ACCOUNT_ID}"
FUNCTION_NAME="ses-forwarder-dev-sesForwarder"
OBJECT_KEY_PREFIX="$(
  cd .. \
    && "$(npm bin)/js-yaml" config.yml | "$(npm bin)/underscore" --outfmt text extract 'config.emailKeyPrefix' 2> /dev/null \
    | sed 's:/*$::'
)"

export AWS_DEFAULT_OUTPUT AWS_DEFAULT_REGION AWS_PROFILE OBJECT_KEY_PREFIX

sls-deploy() {
  "$(npm bin)/sls" --aws-profile "$AWS_PROFILE" --region "$AWS_DEFAULT_REGION" \
    deploy
}

sls-remove() {
  "$(npm bin)/sls" --aws-profile "$AWS_PROFILE" --region "$AWS_DEFAULT_REGION" \
    remove
}

ses-gen-forwarder-rule-file() {
  # NOTE: The ../data/ses-forwarder-rule.json-template file was genearated using: (NOTE: --output json)
  #   aws ses describe-receipt-rule --rule-set-name "$AWS_SES_RULE_SET_NAME" --rule-name "$AWS_SES_RULE_NAME" --output json --query "Rule"
  # following steps 5 and 6 from: # https://github.com/arithmetric/aws-lambda-ses-forwarder
  # Step 7 is handled by serverless.yml

  # if that doesn't exist, need to: create-receipt-rule-set, create-receipt-rule, and set-active-receipt-rule-set
  # since envsubst is not universally available...
  eval "cat <<EOF
$(< ../data/ses-forwarder-rule.json-template)
EOF
" 2> /dev/null > ../data/ses-forwarder-rule.json
}

ses-add-permission-to-invoke-lambda() {
  # "SES was unable to access the resource arn:aws:lambda:us-west-2:xxxxxxxxxxxx:function:ses-forwarder-dev-sesForwarder.
  # It may not have the necessary permissions. Would you like SES to attempt to add those permissions on your behalf?"
  aws --profile "$AWS_PROFILE" --region "$AWS_DEFAULT_REGION" \
    lambda add-permission \
      --function-name "$FUNCTION_NAME" \
      --statement-id "$(date +%s)" \
      --action lambda:InvokeFunction \
      --principal ses.amazonaws.com \
      --source-account "$AWS_ACCOUNT_ID"
}

ses-create-receipt-rule-set() {
  aws --profile "$AWS_PROFILE" --region "$AWS_DEFAULT_REGION" \
    ses create-receipt-rule-set \
      --rule-set-name "$AWS_SES_RULE_SET_NAME"
}

ses-create-receipt-rule() {
  aws --profile "$AWS_PROFILE" --region "$AWS_DEFAULT_REGION" \
    ses create-receipt-rule \
      --rule-set-name "$AWS_SES_RULE_SET_NAME" \
      --rule "$AWS_SES_RULE_FILE"
}

ses-update-receipt-rule() {
  aws --profile "$AWS_PROFILE" --region "$AWS_DEFAULT_REGION" \
    ses update-receipt-rule \
      --rule-set-name "$AWS_SES_RULE_SET_NAME" \
      --rule "$AWS_SES_RULE_FILE"
}

ses-set-active-receipt-rule-set() {
  aws --profile "$AWS_PROFILE" --region "$AWS_DEFAULT_REGION" \
    ses set-active-receipt-rule-set \
      --rule-set-name "$AWS_SES_RULE_SET_NAME"
}

s3-rm() {
  aws --profile "$AWS_PROFILE" --region "$AWS_DEFAULT_REGION" \
    s3 rm "s3://${BUCKET_NAME}" \
      --recursive
}

ses-delete-receipt-rule() {
  aws --profile "$AWS_PROFILE" --region "$AWS_DEFAULT_REGION" \
    ses delete-receipt-rule \
      --rule-set-name "$AWS_SES_RULE_SET_NAME" \
      --rule-name "$AWS_SES_RULE_NAME"
}

ses-delete-receipt-rule-set() {
  aws --profile "$AWS_PROFILE" --region "$AWS_DEFAULT_REGION" \
    ses delete-receipt-rule-set \
      --rule-set-name "$AWS_SES_RULE_SET_NAME"
}

cd ..

ACTIVE_RULE_SET="$(
  aws --profile "$AWS_PROFILE" --region "$AWS_DEFAULT_REGION" \
    ses describe-active-receipt-rule-set \
      --query "Metadata.Name"
)"

# aws ses list-identities --query "Identities"

if [[ "$1" = "deploy" ]]; then
  sls-deploy
  ses-add-permission-to-invoke-lambda
  [[ "$ACTIVE_RULE_SET" = "None" ]] && ses-create-receipt-rule-set
  ses-create-receipt-rule
  ses-set-active-receipt-rule-set
elif [[ "$1" = "remove" ]]; then
  # couldn't get https://www.npmjs.com/package/serverless-s3-remover to work: sls s3remove
  s3-rm
  sls-remove
  # An error occurred (RuleSetDoesNotExist) when calling the DeleteReceiptRule operation: Rule set does not exist: ses-forwarder-rule-set
  ses-delete-receipt-rule
  #ses-delete-receipt-rule-set
fi
