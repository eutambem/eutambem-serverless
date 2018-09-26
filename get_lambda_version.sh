#!/bin/sh

COMMAND="curl https://circleci.com/api/v1.1/project/github/eutambem/eutambem-backend?filter=successful"
   
RESULT=$(${COMMAND})

LAST_SUCCESSFUL_UPLOAD=$(echo $RESULT | jq '[ 
  .[] | 
  select(.workflows.job_name | contains("upload")) |
  { build_num } ] | .[0].build_num '
)

if [ $LAST_SUCCESSFUL_UPLOAD = 'null' ]; then
  echo 'No successful build for the lambda was found. Exiting with error.'
  exit 1 
fi

echo 'Last succesful build (and upload to s3) for the lambda: '$LAST_SUCCESSFUL_UPLOAD
echo $LAST_SUCCESSFUL_UPLOAD > lambda_version.txt