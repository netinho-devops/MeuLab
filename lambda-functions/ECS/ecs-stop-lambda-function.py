import json
import boto3
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

client = boto3.client('ecs')

def lambda_handler(event, context):
    cluster = event["cluster"]
    service_names = event["service_names"]
    service_desired_count = int(event["service_desired_count"])

    for service_name in service_names.split(","):
        response = client.update_service(
            cluster=cluster,
            service=service_name,
            desiredCount=service_desired_count
            )

        logger.info("Updated {0} service in {1} cluster with desire count set to {2} tasks".format(service_name, cluster, service_desired_count))

    return {
        'statusCode': 200,
        'new_desired_count': service_desired_count
    }