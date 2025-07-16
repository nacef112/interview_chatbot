#!/bin/bash

echo "----------------------------------- IMPORTANT NOTES: --------------------------------------"
echo "This script configures your AWS account for deployment of the AI interviewer application."
echo "Run the script from your terminal (with the AWS/SAM CLI installed) as follows:"
echo "$0 <AWS_PUBLIC_ACCESS_KEY> <AWS_SECRET_ACCESS_KEY> <AWS_REGION> <S3_BUCKET>"; 
echo
echo "Or if you prefer, export those variables as environment variables or even modify this file "
echo "directly defining the appropriate variables with the keys you generated and chosen bucket name"
echo "Then, run without arguments the script: "; echo "$0    "; 
echo 
echo "Note: if a 'BucketAlreadyOwnedByYou' error arises, ignore it: it means you are running this"
echo "script attempting to create an S3 bucket that already exists. This is not a problem. "
echo "Similarly, if 'ResourceInUseException' arises creating the Dynamo table, you can ignore it."
echo "-------------------------------------------------------------------------------------------"
echo 

AWS_PUBLIC_ACCESS_KEY=${1:-${AWS_PUBLIC_ACCESS_KEY}}
AWS_SECRET_ACCESS_KEY=${2:-${AWS_SECRET_ACCESS_KEY}}
AWS_REGION=${3:-${AWS_REGION}}
BUCKET_NAME=${4:-${S3_BUCKET}}

if [ -z "$AWS_PUBLIC_ACCESS_KEY" ]
then
    echo "Error: AWS_PUBLIC_ACCESS_KEY cannot be empty!"; echo; exit
fi
if [ -z "$AWS_SECRET_ACCESS_KEY" ]
then
    echo "Error: AWS_SECRET_ACCESS_KEY cannot be empty!"; echo; exit
fi
if [ -z "$AWS_REGION" ]
then
    echo "Error: AWS_REGION cannot be empty!"; echo; exit
fi
if [ -z "$BUCKET_NAME" ]
then
    echo "Error: S3_BUCKET cannot be empty!"; echo; exit
fi


# Configure AWS credentials
echo; echo "Configuring AWS access for '$AWS_PUBLIC_ACCESS_KEY' in $AWS_REGION'"; echo 
aws configure set aws_access_key_id $AWS_PUBLIC_ACCESS_KEY 
aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
aws configure set default.region $AWS_REGION

# Create AWS S3 bucket where build template will be stored
echo "Creating S3 bucket '$BUCKET_NAME' where templates will be stored"
aws s3api create-bucket \
	--bucket $BUCKET_NAME \
	--region $AWS_REGION \
	--create-bucket-configuration LocationConstraint=$AWS_REGION

# Get rid of old templates after 24hours
aws s3api put-bucket-lifecycle-configuration \
	--bucket $BUCKET_NAME  \
	--lifecycle-configuration '{
	    "Rules": [
	        {
	            "Filter": {},
	            "Status": "Enabled",
	            "Expiration": {
	                "Days": 1
	            },
	            "ID": "QuickExpiration"
	        }
	    ]
	}'

# Create AWS DynamoDB table to store interviews. By default named 'interview-sessions', 
# unless DYNAMO_TABLE is otherwise set as environment variable.
TABLE_NAME=${DYNAMO_TABLE:-'interview-sessions'}
echo; echo "Creating DynamoDB table '$TABLE_NAME' to store interview sessions"
aws dynamodb create-table \
	--table-name $TABLE_NAME \
	--attribute-definitions AttributeName=session_id,AttributeType=S \
	--key-schema AttributeName=session_id,KeyType=HASH \
	--billing-mode PAY_PER_REQUEST \
	--region $AWS_REGION

echo
echo "----------------------------------- IMPORTANT NOTES: --------------------------------------"
echo "This file needs to be run just once as all future changes will be reflected in re-deployment."
echo "And ensure that the same S3 bucket and Dynamo table is referenced in deployment. "
echo
echo "You are now ready to deploy your app with the script './aws_deploy.sh' "
echo "-------------------------------------------------------------------------------------------"
echo