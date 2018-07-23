#!/usr/bin/env bash
# Set AWS_PROFILE environment variable if desired.

source "../../common.sh"

COMMAND=$1
if [[ -z "${COMMAND}" ]] && [[ "${COMMAND}" != "create" ]] && [[ "${COMMAND}" != "update" ]]; then
    echo COMMAND=$COMMAND
    echo 'specify a command: create or update'
    exit 1
fi

AWS_CLI_RUN_CMD="${COMMAND}-stack"
AWS_CLI_WAIT_CMD="stack-${COMMAND}-complete"

MANIFEST_FILE="manifest-vpc.yaml"

if [ ! -f ${MANIFEST_FILE} ]; then
    echo "Manifest file not found!"
    exit 1
fi

ENV_NAME=$(/usr/local/bin/yq r $MANIFEST_FILE environment.name)
STACK_NAME="${ENV_NAME}-vpc"

VPC_CIDR=$(/usr/local/bin/yq r $MANIFEST_FILE "environment.vpc.vpc_cidr")
PRIVATE_AZ_A_CIDR=$(/usr/local/bin/yq r $MANIFEST_FILE "environment.vpc.private_az_a_cidr")
PRIVATE_AZ_B_CIDR=$(/usr/local/bin/yq r $MANIFEST_FILE "environment.vpc.private_az_b_cidr")
PRIVATE_AZ_C_CIDR=$(/usr/local/bin/yq r $MANIFEST_FILE "environment.vpc.private_az_c_cidr")
PUBLIC_AZ_A_CIDR=$(/usr/local/bin/yq r $MANIFEST_FILE "environment.vpc.public_az_a_cidr")
PUBLIC_AZ_B_CIDR=$(/usr/local/bin/yq r $MANIFEST_FILE "environment.vpc.public_az_b_cidr")
PUBLIC_AZ_C_CIDR=$(/usr/local/bin/yq r $MANIFEST_FILE "environment.vpc.public_az_c_cidr")


cloudformation_template_file="file://vpc.yaml"

stack_parameters=$(join_strings " " \
  "ParameterKey=VpcCidrParam,ParameterValue=$VPC_CIDR" \
  "ParameterKey=PrivateAZASubnetBlock,ParameterValue=$PRIVATE_AZ_A_CIDR" \
  "ParameterKey=PrivateAZBSubnetBlock,ParameterValue=$PRIVATE_AZ_B_CIDR" \
  "ParameterKey=PrivateAZCSubnetBlock,ParameterValue=$PRIVATE_AZ_C_CIDR" \
  "ParameterKey=PublicAZASubnetBlock,ParameterValue=$PUBLIC_AZ_A_CIDR" \
  "ParameterKey=PublicAZBSubnetBlock,ParameterValue=$PUBLIC_AZ_B_CIDR" \
  "ParameterKey=PublicAZCSubnetBlock,ParameterValue=$PUBLIC_AZ_C_CIDR") 

stack_tags=$(join_strings " " \
  "Key=environment,Value=$ENV_NAME" \
  "Key=role,Value=network" \
  "Key=billing,Value=architecture" \
  "Key=created-by,Value=cloudformation")

aws cloudformation ${AWS_CLI_RUN_CMD} \
  --stack-name $STACK_NAME \
  --parameters $stack_parameters \
  --template-body $cloudformation_template_file \
  --tags $stack_tags \
  --capabilities CAPABILITY_NAMED_IAM

aws cloudformation wait ${AWS_CLI_WAIT_CMD} --stack-name $STACK_NAME
