#!/usr/bin/env bash
# Set AWS_PROFILE environment variable if desired.

COMMAND=$1
if [[ -z "${COMMAND}" ]] && [[ "${COMMAND}" != "create" ]] && [[ "${COMMAND}" != "update" ]]; then
    echo COMMAND=$COMMAND
    echo 'specify a command: create or update'
    exit 1
fi

AWS_CLI_RUN_CMD="${COMMAND}-stack"
AWS_CLI_WAIT_CMD="stack-${COMMAND}-complete"

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
SERVICE_NAME_ARG=$2

for i in $( seq 0 $((SERVICE_COUNT-1)))
do
	SERVICE_NAME=$(/usr/local/bin/yq r $MANIFEST_FILE "environment.application.services[$i].name")
        if [ "${SERVICE_NAME_ARG}" ] && [ "${SERVICE_NAME}" != "${SERVICE_NAME_ARG}" ]; then
            continue
        fi

	STACK_NAME="${ENV_NAME}-${APP_NAME}-${SERVICE_NAME}"

	DESIRED_TASK_COUNT=$(/usr/local/bin/yq r $MANIFEST_FILE "environment.application.services[$i].desired_task_count")
	MIN_TASK_COUNT=$(/usr/local/bin/yq r $MANIFEST_FILE "environment.application.services[$i].min_task_count")
	MAX_TASK_COUNT=$(/usr/local/bin/yq r $MANIFEST_FILE "environment.application.services[$i].max_task_count")

        ALB_LISTENER_PORT=$(/usr/local/bin/yq r $MANIFEST_FILE "environment.application.services[$i].alb_listener_port")
        ALB_LISTENER_PATH=$(/usr/local/bin/yq r $MANIFEST_FILE "environment.application.services[$i].alb_listener_path")
        ALB_LISTENER_RULE_PRIORITY=$(/usr/local/bin/yq r $MANIFEST_FILE "environment.application.services[$i].alb_listener_rule_priority")
        ALB_HEALTH_CHECK_PATH=$(/usr/local/bin/yq r $MANIFEST_FILE "environment.application.services[$i].alb_health_check_path")

        TASK_DEFINITION_NAME=$(/usr/local/bin/yq r $MANIFEST_FILE "environment.application.services[$i].task-definition.name")
        TASK_CPU=$(/usr/local/bin/yq r $MANIFEST_FILE "environment.application.services[$i].task-definition.cpu")
        TASK_MEMORY=$(/usr/local/bin/yq r $MANIFEST_FILE "environment.application.services[$i].task-definition.memory")

        CONTAINER_NAME=$(/usr/local/bin/yq r $MANIFEST_FILE "environment.application.services[$i].task-definition.container.name")
        CONTAINER_NAME="${STACK_NAME}-${CONTAINER_NAME}"
        CONTAINER_PORT=$(/usr/local/bin/yq r $MANIFEST_FILE "environment.application.services[$i].task-definition.container.port")
        CONTAINER_IMAGE=$(/usr/local/bin/yq r $MANIFEST_FILE "environment.application.services[$i].task-definition.container.image")
        CONTAINER_IMAGE_TAG=$(/usr/local/bin/yq r $MANIFEST_FILE "environment.application.services[$i].task-definition.container.image_tag")
	if [ "${CONTAINER_IMAGE_TAG}" == "null" ]; then
		CONTAINER_IMAGE_TAG=latest
	fi

	cloudformation_template_file="file://${SERVICE_NAME}/cf-template.yaml"
	source ${SERVICE_NAME}/cf-params.sh

	aws cloudformation ${AWS_CLI_RUN_CMD} \
	  --stack-name $STACK_NAME \
	  --parameters $stack_parameters \
	  --template-body $cloudformation_template_file \
	  --tags $stack_tags \
	  --capabilities CAPABILITY_NAMED_IAM

	#aws cloudformation wait ${AWS_CLI_WAIT_CMD} --stack-name $STACK_NAME
done
