import json
import boto3
import os


def get_permission_set_name(permission_set_arn):
    """
    Retrieves the name of a permission set using its ARN.
    """
    sso_admin = boto3.client('sso-admin')

    # Get the instance ARN
    instance_response = sso_admin.list_instances()
    instance_arn = instance_response['Instances'][0]['InstanceArn']

    # Describe the permission set
    response = sso_admin.describe_permission_set(
        InstanceArn=instance_arn,
        PermissionSetArn=permission_set_arn
    )

    return response['PermissionSet']['Name']


def send_sns(message):
    """
    Sends an SNS notification with details about the permission set assignment.
    """
    client = boto3.client('sns')

    ps_assigner = message['detail']['userIdentity']['arn']
    ps_arn = message['detail']['responseElements']['accountAssignmentCreationStatus']['permissionSetArn']
    ps_date_time_assigned = message['detail']['eventTime']
    ps_target_acct = message['detail']['responseElements']['accountAssignmentCreationStatus']['targetId']
    ps_name = get_permission_set_name(ps_arn)

    response = client.publish(
        TargetArn=os.environ['SNS_TOPIC_ARN'],
        Message=(
            f"The following permission set has been assigned:\n\n"
            f"PERMISSION SET NAME: {ps_name}\n"
            f"PERMISSION SET ARN: {ps_arn}\n"
            f"AWS ACCOUNT: {ps_target_acct}\n"
            f"DATE/TIME: {ps_date_time_assigned}\n"
            f"ASSIGNED BY: {ps_assigner}."
        ),
        Subject="Heyyyyyy!!! Listen 🙂"
    )


def lambda_handler(event, context):
    """
    AWS Lambda handler function.
    """
    send_sns(event)