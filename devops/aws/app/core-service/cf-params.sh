#!/usr/bin/env bash

source "../../common.sh"

if [ -z "${MONGODB_DATABASE}" ] || [ -z "${MONGODB_USERNAME}" ] || [ -z "${MONGODB_PASSWORD}" ]; then
	echo "The following ENV variables need to be defined: MONGODB_DATABASE, MONGODB_USERNAME, MONGODB_PASSWORD"
	continue
fi

# Escape double quotes
METEOR_SETTINGS=$(echo $METEOR_SETTINGS | sed 's/"/\\"/g')

stack_parameters=$(join_strings " " \
  "ParameterKey=CloudFormationVPCStackName,ParameterValue=$VPC_STACK_NAME" \
  "ParameterKey=CloudFormationECSStackName,ParameterValue=$ECS_STACK_NAME" \
  "ParameterKey=AppName,ParameterValue=$APP_NAME" \
  "ParameterKey=EnvName,ParameterValue=$ENV_NAME" \
  "ParameterKey=ServiceName,ParameterValue=$SERVICE_NAME" \
  "ParameterKey=CertificateArn,ParameterValue=$CERTIFICATE_ARN" \
  "ParameterKey=DesiredTaskCount,ParameterValue=$DESIRED_TASK_COUNT" \
  "ParameterKey=MinTaskCount,ParameterValue=$MIN_TASK_COUNT" \
  "ParameterKey=MaxTaskCount,ParameterValue=$MAX_TASK_COUNT" \
  "ParameterKey=ALBListenerPort,ParameterValue=$ALB_LISTENER_PORT" \
  "ParameterKey=ALBListenerPath,ParameterValue=$ALB_LISTENER_PATH" \
  "ParameterKey=ALBListenerRulePriority,ParameterValue=$ALB_LISTENER_RULE_PRIORITY" \
  "ParameterKey=ALBHealthCheckPath,ParameterValue=$ALB_HEALTH_CHECK_PATH" \
  "ParameterKey=TaskDefinitionName,ParameterValue=$TASK_DEFINITION_NAME" \
  "ParameterKey=TaskCpu,ParameterValue=$TASK_CPU" \
  "ParameterKey=TaskMemory,ParameterValue=$TASK_MEMORY" \
  "ParameterKey=ContainerName,ParameterValue=$CONTAINER_NAME" \
  "ParameterKey=ContainerPort,ParameterValue=$CONTAINER_PORT" \
  "ParameterKey=ContainerImage,ParameterValue=$CONTAINER_IMAGE" \
  "ParameterKey=ContainerImageTag,ParameterValue=$CONTAINER_IMAGE_TAG" \
  "ParameterKey=ReactionAuth,ParameterValue=$REACTION_AUTH" \
  "ParameterKey=ReactionUser,ParameterValue=$REACTION_USER" \
  "ParameterKey=ReactionEmail,ParameterValue=$REACTION_EMAIL" \
  "ParameterKey=RootDomain,ParameterValue=$ROOT_DOMAIN" \
  "ParameterKey=MongoDBHost,ParameterValue=$MONGODB_HOST" \
  "ParameterKey=MongoDBPort,ParameterValue=$MONGODB_PORT" \
  "ParameterKey=MongoDBQueryString,ParameterValue=$MONGODB_QUERY_STRING" \
  "ParameterKey=MongoDBDatabase,ParameterValue=$MONGODB_DATABASE" \
  "ParameterKey=MongoDBUsername,ParameterValue=$MONGODB_USERNAME" \
  "ParameterKey=MongoDBPassword,ParameterValue=$MONGODB_PASSWORD" \
  "ParameterKey=MongoDBOplogUrl,ParameterValue=$MONGODB_OPLOG_URL" \
  "ParameterKey=CloudfrontUrl,ParameterValue=$CLOUDFRONT_URL" \
  "ParameterKey=SkipFixtures,ParameterValue=$SKIP_FIXTURES" \
  "ParameterKey=MeteorSettings,ParameterValue='\"$METEOR_SETTINGS\"'")

#echo $stack_parameters

stack_tags=$(join_strings " " \
  "Key=${APP_NAME}/environment,Value=$ENV_NAME" \
  "Key=${APP_NAME}/app,Value=$APP_NAME" \
  "Key=${APP_NAME}/app-role,Value=$SERVICE_NAME" \
  "Key=${APP_NAME}/billing,Value=architecture" \
  "Key=${APP_NAME}/created-by,Value=cloudformation")
