#!/bin/sh
set -e

#Initialize build_number annotation variable
annotation_variable='build_number'

# Grab the current build information and output to json
printf '\nBuild ID: %s' "$CF_BUILD_ID"

if [ "$ANNOTATION_NAME" = '${{ANNOTATION_NAME}}' ]
then
    printf '\n\nANNOTATION_PREFIX is empty. Annotation name will be build_number'
else
    printf '\n\nAnnotation name passed in: %s' "$ANNOTATION_NAME"
    annotation_variable="$ANNOTATION_NAME"
fi

printf '\n\nCurrent build JSON\n'
codefresh get build $CF_BUILD_ID -o json

# Use jq to traverse the json and grab the pipeline id
pipelineid=$(codefresh get build $CF_BUILD_ID -o json | jq '."pipeline-Id"')
printf '\nJSON parsed pipeline-Id: %s \n' "$pipelineid"

# If the annotation build_number already exists, increment it by 1
# If the annotation build_number doesn't exist, initialize it at 1
printf '\nGet annotation JSON value using jq\n'
build_number=$(codefresh get annotation pipeline $pipelineid $annotation_variable -o json | jq '.value' -j) || true
printf '\nCurrent value: %s' "$build_number"

# Check if the variable RETRIEVE_CURRENT_VALUE_ONLY is set to true to skip bumping the build number
if [ "$RETRIEVE_CURRENT_VALUE_ONLY" = true ]
then
    printf '\nRetrieve value only variable set. Exporting existing build number to CF_BUILD_NUMBER\n'
    echo CF_BUILD_NUMBER="$build_number" >> /meta/env_vars_to_export
    exit 0
fi

new_build_number=$((build_number+1))

printf '\nBumped value: %s \n' "$new_build_number"
printf '\nCreating annotation: '
codefresh create annotation pipeline $pipelineid $annotation_variable=$new_build_number

printf '\nUpdated annotation build_number JSON\n'
codefresh get annotation pipeline $pipelineid $annotation_variable -o json

printf '\nExporting build number to CF_BUILD_NUMBER\n'
echo CF_BUILD_NUMBER="$new_build_number" >> /meta/env_vars_to_export