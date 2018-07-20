#!/usr/bin/env bash
# Set AWS_PROFILE environment variable if desired.

function join_strings {
    local IFS="$1";
    shift;
    echo "$*";
}

MANIFEST_FILE="manifest-app.yaml"

if [ ! -f ${MANIFEST_FILE} ]; then
    echo "Manifest file not found!"
    exit 1
fi

ENV_NAME=$(/usr/local/bin/yq r $MANIFEST_FILE "environment.name")
APP_NAME=$(/usr/local/bin/yq r $MANIFEST_FILE "environment.application.name")
ECS_CLUSTER_NAME=$(/usr/local/bin/yq r $MANIFEST_FILE "environment.application.ecs_cluster")
VPC_STACK_NAME="${ENV_NAME}-vpc"
ECS_STACK_NAME="${ENV_NAME}-ecs-${ECS_CLUSTER_NAME}"
CERTIFICATE_ARN=$(/usr/local/bin/yq r $MANIFEST_FILE "environment.application.certificate_arn")

SERVICE_COUNT=$(/usr/local/bin/yq r $MANIFEST_FILE 'environment.application.services.*.name' | wc -l | xargs)

for i in $( seq 0 $((SERVICE_COUNT-1)))
do
	SERVICE_NAME=$(/usr/local/bin/yq r $MANIFEST_FILE "environment.application.services[$i].name")
	STACK_NAME="${ENV_NAME}-${APP_NAME}-${SERVICE_NAME}"

	DESIRED_TASK_COUNT=$(/usr/local/bin/yq r $MANIFEST_FILE "environment.application.services[$i].desired_task_count")
	MIN_TASK_COUNT=$(/usr/local/bin/yq r $MANIFEST_FILE "environment.application.services[$i].min_task_count")
	MAX_TASK_COUNT=$(/usr/local/bin/yq r $MANIFEST_FILE "environment.application.services[$i].max_task_count")

        TASK_DEFINITION_NAME=$(/usr/local/bin/yq r $MANIFEST_FILE "environment.application.services[$i].task-definition.name")
        TASK_CPU=$(/usr/local/bin/yq r $MANIFEST_FILE "environment.application.services[$i].task-definition.cpu")
        TASK_MEMORY=$(/usr/local/bin/yq r $MANIFEST_FILE "environment.application.services[$i].task-definition.memory")

        CONTAINER_NAME=$(/usr/local/bin/yq r $MANIFEST_FILE "environment.application.services[$i].task-definition.container.name")
        CONTAINER_NAME="${STACK_NAME}-${CONTAINER_NAME}"
        CONTAINER_PORT=$(/usr/local/bin/yq r $MANIFEST_FILE "environment.application.services[$i].task-definition.container.port")
        CONTAINER_IMAGE=$(/usr/local/bin/yq r $MANIFEST_FILE "environment.application.services[$i].task-definition.container.image")
        CONTAINER_IMAGE_TAG=$(/usr/local/bin/yq r $MANIFEST_FILE "environment.application.services[$i].task-definition.container.image_tag")

	cloudformation_template_file="file://${SERVICE_NAME}.yaml"

        # Escape double quotes
	METEOR_SETTINGS=$(echo $METEOR_SETTINGS | sed 's/"/\\"/g')

	stack_parameters=$(join_strings " " \
	  "ParameterKey=CloudFormationVPCStackName,ParameterValue=$VPC_STACK_NAME" \
	  "ParameterKey=CloudFormationECSStackName,ParameterValue=$ECS_STACK_NAME" \
	  "ParameterKey=AppName,ParameterValue=$APP_NAME" \
	  "ParameterKey=EnvName,ParameterValue=$ENV_NAME" \
	  "ParameterKey=CertificateArn,ParameterValue=$CERTIFICATE_ARN" \
	  "ParameterKey=DesiredTaskCount,ParameterValue=$DESIRED_TASK_COUNT" \
	  "ParameterKey=MinTaskCount,ParameterValue=$MIN_TASK_COUNT" \
	  "ParameterKey=MaxTaskCount,ParameterValue=$MAX_TASK_COUNT" \
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
	  "ParameterKey=MongoDBDatabase,ParameterValue=$MONGODB_DB" \
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

	aws cloudformation create-stack \
	  --stack-name $STACK_NAME \
	  --parameters $stack_parameters \
	  --template-body $cloudformation_template_file \
	  --tags $stack_tags \
	  --capabilities CAPABILITY_NAMED_IAM

	aws cloudformation wait stack-create-complete --stack-name $STACK_NAME
done
