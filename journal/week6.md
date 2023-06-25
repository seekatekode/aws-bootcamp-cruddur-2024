# Week 6 — Deploying Containers
## Test RDS Connecetion

We added this `test` script into `db` so we can easily check our connection from our container. Then ran `chmod u+x backend-flask/bin/db/test`

```sh
#!/usr/bin/env python3

import psycopg
import os
import sys

connection_url = os.getenv("CONNECTION_URL")

conn = None
try:
  print('attempting connection')
  conn = psycopg.connect(connection_url)
  print("Connection successful!")
except psycopg.Error as e:
  print("Unable to connect to the database:", e)
finally:
  conn.close()
```

![F2037F1A-A306-4CB3-BEF0-FFCBFFAE9298](https://github.com/seekatekode/aws-bootcamp-cruddur-2024/assets/133314947/11846a5a-ad69-45b8-92ea-d9f25cdd89fa)

Then ran `chmod u+x backend-flask/bin/db/test` , added `PROD` to `connection_url = os.getenv("CONNECTION_URL")`

 **Running ./bin/db/test was not successful unless I remove `PROD` ,then it worked right away.**
 
 ![FF97ACD5-31CC-419D-8EA4-183658EC8C83](https://github.com/seekatekode/aws-bootcamp-cruddur-2024/assets/133314947/1f4d29ea-5f83-497d-a0f0-8a91d6056734)

We then ran `export GITPOD_IP=$(curl ifconfig.me)`, then `./bin/rds/update-sg-rule`. This command did not work for me, so I received the error `An error occurred (InvalidGroupId.Malformed) when calling the ModifySecurityGroupRules operation: Invalid id: "sg-0b3b...`. Since this did not work, I wasn't able to receive `Connection successful` after running `./bin/db/test` I reached out in Discord after trying a few steps with no luck and it was determined my inbound rules were not set correctly. 




## Task Flask Script

We added the following endpoint for our flask app:

```py
@app.route('/api/health-check')
def health_check():
  return {'success': True}, 200
```


![DC631736-904B-4CE0-8912-9E726F4D1A4F](https://github.com/seekatekode/aws-bootcamp-cruddur-2024/assets/133314947/e76e144e-6e26-4b7a-bc69-8ef6ecc5e65d)


We then created a new bin script at `bin/flask/health-check` and ran `chmod u+x ./bin/flask/health-check` 

```py
#!/usr/bin/env python3

import urllib.request

response = urllib.request.urlopen('http://localhost:4567/api/health-check')
if response.getcode() == 200:
  print("Flask server is running")
else:
  print("Flask server is not running")
```

![C4582FD0-F2FA-445B-89CA-8208B39DD6F1](https://github.com/seekatekode/aws-bootcamp-cruddur-2024/assets/133314947/1ecce3b4-9d2f-4d83-8444-849d27f2cb2f)

**We then ran the command `./bin/flask/health-check` and it didn't pass the first multiple tries until I stopped the workspace overnight and restarted the same workspace the next morning.** 


![66C73E96-4A57-4E8F-9C74-9930E0CB6821](https://github.com/seekatekode/aws-bootcamp-cruddur-2024/assets/133314947/0ecc1a22-218b-443b-be34-bb4d2ce46fa9)

![98C237A0-B05E-47E8-9AB0-B2A394B6B036_4_5005_c](https://github.com/seekatekode/aws-bootcamp-cruddur-2024/assets/133314947/e23c5c88-624d-4063-884a-e8661676dde9)



## Create CloudWatch Log Group

We then went over to AWS CloudWatch to create a new CloudWatch group. I attempted to run `aws logs create-log-group --log-group-name cruddur`, but received this error. 

**An error occurred (ResourceAlreadyExistsException) when calling the CreateLogGroup operation: The specified log group already exists**

When I checked AWS log groups the group called `cruddur` already existed, so I created another one called `/cruddur/fargate-cluster`and set the retention for `1 day` to keep the data from being stored for too long since this will be costly.

`sh
aws logs create-log-group --log-group-name "/cruddur/fargate-cluster"
aws logs put-retention-policy --log-group-name "/cruddur/fargate-cluster" --retention-in-days 1`


![7204D500-AA5D-41C7-8A87-E91A09E729AA](https://github.com/seekatekode/aws-bootcamp-cruddur-2024/assets/133314947/748def64-bb57-41b4-a3ee-800d721961b9)


## Create ECS Cluster

Using AWS CLI, we then created a ECS Cluster **to simplify the management, scalability, and availability of containerized applications, making it easier to deploy and run them efficiently in a distributed computing environment.**

```sh
aws ecs create-cluster \
--cluster-name cruddur \
--service-connect-defaults namespace=cruddur
```

<img width="1094" alt="Screenshot 2023-06-15 at 8 41 29 PM" src="https://github.com/seekatekode/aws-bootcamp-cruddur-2024/assets/133314947/47194730-38ce-492c-980e-2024b0f62fb3">


### Gaining Accesss to ECS Fargate Container

## Create ECR repo and push image

### Login to ECR

```sh
aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com"
```

### For Base-image python
We ran this in `backend-flask` and it returned data. 

```sh
aws ecr create-repository \
  --repository-name cruddur-python \
  --image-tag-mutability MUTABLE
```


![10B66722-142C-4437-A2EB-61D2BF389616](https://github.com/seekatekode/aws-bootcamp-cruddur-2024/assets/133314947/e0f59590-b905-4043-96f7-250490f8f1e0)

#### Set URL

We then set the URL. 
```sh
export ECR_PYTHON_URL="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/cruddur-python"
echo $ECR_PYTHON_URL
```

#### Pull Image

```sh
docker pull python:3.10-slim-buster
```

![44C6778B-632C-40E1-BCC3-E8B3736D7CA4_4_5005_c](https://github.com/seekatekode/aws-bootcamp-cruddur-2024/assets/133314947/2ec667bc-7e43-4742-a96f-825f5752055d)

#### Tag Image

```sh
docker tag python:3.10-slim-buster $ECR_PYTHON_URL:3.10-slim-buster
```
![DB33D826-5EA8-4EAE-B466-AB52D8EE889B](https://github.com/seekatekode/aws-bootcamp-cruddur-2024/assets/133314947/1c6b3332-6d11-4648-824e-7791943669d2)

#### Push Image

```sh
docker push $ECR_PYTHON_URL:3.10-slim-buster
```

![1E0B6014-6052-490E-9656-F1A766E07E80_4_5005_c](https://github.com/seekatekode/aws-bootcamp-cruddur-2024/assets/133314947/f711d274-0468-41ed-9168-30408356f500)



![8851C834-6FAB-478F-B82F-8B0AAE250183](https://github.com/seekatekode/aws-bootcamp-cruddur-2024/assets/133314947/77e7b656-d062-4c0e-b889-759ab248fa73)


### For Flask

**We then updated the `Dockerfile`** ...In our flask `Dockerfile` we updated the `FROM` to our own eg instead of using DockerHub's python image > remember to put the :latest tag on the end



![0229306D-FCBA-4404-ACA7-D5DC17F6D7F8_4_5005_c](https://github.com/seekatekode/aws-bootcamp-cruddur-2024/assets/133314947/667e0431-748f-473a-927a-ffd25457c928)


**We then selected `Compose Up- Select Services`, selected `backend-flask` and `db`, but this was unsuccessful, so we untagged and retagged.**

**When performing the `health-check` it was successful**


![86B60C16-B037-4253-9F1C-816C225CC5C2_4_5005_c](https://github.com/seekatekode/aws-bootcamp-cruddur-2024/assets/133314947/b9338a39-3b59-4209-8a00-afb2d9accaef)

![CB661956-1995-4B64-81C1-5C59AB97E276_4_5005_c](https://github.com/seekatekode/aws-bootcamp-cruddur-2024/assets/133314947/ecadde6b-b5b1-45ff-abf5-bc1f0bcfd883)


#### Create Repo
```sh
aws ecr create-repository \
  --repository-name backend-flask \
  --image-tag-mutability MUTABLE
```


#### Build Image
```sh
docker build -t backend-flask .
```
![4A31AA7A-1AEC-473E-A6DA-50AF3EB46543](https://github.com/seekatekode/aws-bootcamp-cruddur-2024/assets/133314947/5976e4a1-6bb1-402f-aa4e-9b8ae392759d)


#### Tag Image

```sh
docker tag backend-flask:latest $ECR_BACKEND_FLASK_URL:latest
```


#### Push Image

```sh
docker push $ECR_BACKEND_FLASK_URL:latest
```


### Create Services

```sh
aws ecs create-service --cli-input-json file://aws/json/backend-flask-serv.json
```

```sh
aws ecs create-service --cli-input-json file://aws/json/frontend-react-js-serv.json
```

> Auto Assign is not supported by EC2 launch type for services

This is for when we are uing a NetworkMode of awsvpc
> --network-configuration "awsvpcConfiguration={subnets=[$DEFAULT_SUBNET_IDS],securityGroups=[$SERVICE_CRUD_SG],assignPublicIp=ENABLED}"

https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-networking.html


### Create Task and Exection Roles for Task Defintion


#### Create ExecutionRole

```sh
aws iam create-role \
    --role-name CruddurServiceExecutionRole \
    --assume-role-policy-document "{
  \"Version\":\"2012-10-17\",
  \"Statement\":[{
    \"Action\":[\"sts:AssumeRole\"],
    \"Effect\":\"Allow\",
    \"Principal\":{
      \"Service\":[\"ecs-tasks.amazonaws.com\"]
    }
  }]
}"
```

## Register Task Defintions

### Passing Senstive Data to Task Defintion

https://docs.aws.amazon.com/AmazonECS/latest/developerguide/specifying-sensitive-data.html
https://docs.aws.amazon.com/AmazonECS/latest/developerguide/secrets-envvar-ssm-paramstore.html

```sh
aws ssm put-parameter --type "SecureString" --name "/cruddur/backend-flask/AWS_ACCESS_KEY_ID" --value $AWS_ACCESS_KEY_ID
aws ssm put-parameter --type "SecureString" --name "/cruddur/backend-flask/AWS_SECRET_ACCESS_KEY" --value $AWS_SECRET_ACCESS_KEY
aws ssm put-parameter --type "SecureString" --name "/cruddur/backend-flask/CONNECTION_URL" --value $PROD_CONNECTION_URL
aws ssm put-parameter --type "SecureString" --name "/cruddur/backend-flask/ROLLBAR_ACCESS_TOKEN" --value $ROLLBAR_ACCESS_TOKEN
aws ssm put-parameter --type "SecureString" --name "/cruddur/backend-flask/OTEL_EXPORTER_OTLP_HEADERS" --value "x-honeycomb-team=$HONEYCOMB_API_KEY"
```

![08FA55C8-8711-450A-9CB9-905CDF55DEB7](https://github.com/seekatekode/aws-bootcamp-cruddur-2024/assets/133314947/f446c45e-de4c-4f2d-8976-0e2c48610870)


#### Create TaskRole

```sh
aws iam create-role \
    --role-name CruddurTaskRole \
    --assume-role-policy-document "{
  \"Version\":\"2012-10-17\",
  \"Statement\":[{
    \"Action\":[\"sts:AssumeRole\"],
    \"Effect\":\"Allow\",
    \"Principal\":{
      \"Service\":[\"ecs-tasks.amazonaws.com\"]
    }
  }]
}"


```

### Create Json file

Created a new folder called `aws/task-defintions` and added the following files, but replaced with own credentials:

`backend-flask.json`

```json
{
  "family": "backend-flask",
  "executionRoleArn": "arn:aws:iam::AWS_ACCOUNT_ID:role/CruddurServiceExecutionRole",
  "taskRoleArn": "arn:aws:iam::AWS_ACCOUNT_ID:role/CruddurTaskRole",
  "networkMode": "awsvpc",
  "containerDefinitions": [
    {
      "name": "backend-flask",
      "image": "BACKEND_FLASK_IMAGE_URL",
      "cpu": 256,
      "memory": 512,
      "essential": true,
      "portMappings": [
        {
          "name": "backend-flask",
          "containerPort": 4567,
          "protocol": "tcp", 
          "appProtocol": "http"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
            "awslogs-group": "cruddur",
            "awslogs-region": "us-east-1",
            "awslogs-stream-prefix": "backend-flask"
        }
      },
      "environment": [
        {"name": "OTEL_SERVICE_NAME", "value": "backend-flask"},
        {"name": "OTEL_EXPORTER_OTLP_ENDPOINT", "value": "https://api.honeycomb.io"},
        {"name": "AWS_COGNITO_USER_POOL_ID", "value": ""},
        {"name": "AWS_COGNITO_USER_POOL_CLIENT_ID", "value": ""},
        {"name": "FRONTEND_URL", "value": ""},
        {"name": "BACKEND_URL", "value": ""},
        {"name": "AWS_DEFAULT_REGION", "value": ""}
      ],
      "secrets": [
        {"name": "AWS_ACCESS_KEY_ID"    , "valueFrom": "arn:aws:ssm:AWS_REGION:AWS_ACCOUNT_ID:parameter/cruddur/backend-flask/AWS_ACCESS_KEY_ID"},
        {"name": "AWS_SECRET_ACCESS_KEY", "valueFrom": "arn:aws:ssm:AWS_REGION:AWS_ACCOUNT_ID:parameter/cruddur/backend-flask/AWS_SECRET_ACCESS_KEY"},
        {"name": "CONNECTION_URL"       , "valueFrom": "arn:aws:ssm:AWS_REGION:AWS_ACCOUNT_ID:parameter/cruddur/backend-flask/CONNECTION_URL" },
        {"name": "ROLLBAR_ACCESS_TOKEN" , "valueFrom": "arn:aws:ssm:AWS_REGION:AWS_ACCOUNT_ID:parameter/cruddur/backend-flask/ROLLBAR_ACCESS_TOKEN" },
        {"name": "OTEL_EXPORTER_OTLP_HEADERS" , "valueFrom": "arn:aws:ssm:AWS_REGION:AWS_ACCOUNT_ID:parameter/cruddur/backend-flask/OTEL_EXPORTER_OTLP_HEADERS" }
        
      ]
    }
  ]
}
```


### Register Task Defintion

We registered the task definition for only the `backend-end`

```sh
aws ecs register-task-definition --cli-input-json file://aws/task-defintions/backend-flask.json
```

## Defaults

```sh
export DEFAULT_VPC_ID=$(aws ec2 describe-vpcs \
--filters "Name=isDefault, Values=true" \
--query "Vpcs[0].VpcId" \
--output text)
echo $DEFAULT_VPC_ID
```

```sh
export DEFAULT_SUBNET_IDS=$(aws ec2 describe-subnets  \
 --filters Name=vpc-id,Values=$DEFAULT_VPC_ID \
 --query 'Subnets[*].SubnetId' \
 --output json | jq -r 'join(",")')
echo $DEFAULT_SUBNET_IDS
```


### Create Security Group


```sh
export CRUD_SERVICE_SG=$(aws ec2 create-security-group \
  --group-name "crud-srv-sg" \
  --description "Security group for Cruddur services on ECS" \
  --vpc-id $DEFAULT_VPC_ID \
  --query "GroupId" --output text)
echo $CRUD_SERVICE_SG
```


```sh
aws ec2 authorize-security-group-ingress \
  --group-id $CRUD_SERVICE_SG \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0
```

**We then created a service via the AWS console. When I attempted to select the task definition it threw this error:**

```" The selected task definition is not compatible with the selected compute strategy. "```

I took a look at my code again and noticed it was missing a few pieces of code since I was using the json code for `task-definitions` via the  **week 6 fargate** instructions instead of the code from the week 6 repo. So in other words, the code wasn't exactly like Andrew's. After making these corrections I still wasn't able to create the service, but this time it was similar to Andrew's issue with permissions. 

### ERRORS THROWN WHEN ATTEMPTING TO DEPLOY/ CREATE SERVICE 

**##ERROR 1**

**"Task stopped at: 6/22/2023, 09:28:18 UTC
ResourceInitializationError: unable to pull secrets or registry auth: execution resource retrieval failed: unable to retrieve ecr registry auth: service call has been retried 1 time(s): AccessDeniedException: User: arn:aws:sts::181.........:assumed-role/CruddurServiceExecutionRole/97e56dadd03045deaa5e8b6c688ec319 is not authorized to perform: ecr:GetAuthorizationToken on resource: * because no identity-based policy allows the ecr:GetAuthorizationToken action status code: 400, request id: 802fafcf-b0af-4d34-a105-67c8c3c9b153"**

To resolve this error `CruddurServiceExecutionPolicy` had to be updated to include the permission `GetAuthorizationToken`. 


![F06A40ED-008C-4F26-9F28-672F9F4665AF](https://github.com/seekatekode/aws-bootcamp-cruddur-2024/assets/133314947/a2facfd7-3ed3-423d-984d-9c600ff406c4)

**##ERROR 2**

"Task stopped at: 6/22/2023, 10:01:58 UTC
ResourceInitializationError: failed to validate logger args: create stream has been retried 1 times: failed to create Cloudwatch log stream: AccessDeniedException: User: arn:aws:sts::1819......:assumed-role/CruddurServiceExecutionRole/3caf853ecb00491db67740079d4a02a7 is not authorized to perform: logs:CreateLogStream on resource: arn:aws:logs:us-east-1:181905276501:log-group:cruddur:log-stream:backend-flask/backend-flask/3caf853ecb00491db67740079d4a02a7 because no identity-based policy allows the logs:CreateLogStream action status code: 400, request id: 061e0f7c-b758-4b95-8fab-c791d3f8665e : exit status 1"

**To resolve this error we had to add `CloudWatchFullAccess` policy to the `CruddurServiceExecutionRole`.**


![374CF3ED-311B-4552-940D-91B2565517E2](https://github.com/seekatekode/aws-bootcamp-cruddur-2024/assets/133314947/11a431d4-eaa3-4f4d-84c3-0a878bb8af4d)

**##ERROR 3**

"Task stopped at: 6/22/2023, 10:28:57 UTC
CannotPullContainerError: pull image manifest has been retried 1 time(s): failed to resolve ref 181905276501.dkr.ecr.us-east-1.amazonaws.com/backend-flask:latest: pulling from host 181905276501.dkr.ecr.us-east-1.amazonaws.com failed with status code [manifests latest]: 403 Forbidden"

**To resolve this issue we added these inline policies**

```sh
"ecr: BatchCheckLayerAvailability"
"ecr: GetDownloadUrIForLayer",
"ecr: BatchGetImage",
"logs: CreateLogStream"
"logs: PutLogEvents
```


**The task kept failing and I had to keep creating the service repeatedly, so the next thing was to create the service via AWS CLI. We created a folder called `service-backend-flask.json`...**

## Defaults

```sh
export DEFAULT_VPC_ID=$(aws ec2 describe-vpcs \
--filters "Name=isDefault, Values=true" \
--query "Vpcs[0].VpcId" \
--output text)

echo $DEFAULT_VPC_ID
```

```sh
export DEFAULT_SUBNET_IDS=$(aws ec2 describe-subnets  \
 --filters Name=vpc-id,Values=$DEFAULT_VPC_ID \
 --query 'Subnets[*].SubnetId' \
 --output json | jq -r 'join(",")')
 
echo $DEFAULT_SUBNET_IDS
```

**After editing the code in `service-backend-flask.json`we ran**

```
aws ecs create-service --cli-input-json file://aws/json/service-backend-flask.json
``` 

**This returned data in the terminal and in the AWS console.**

**We then connected to the container**
 ```sh
aws ecs execute-command  \
--region $AWS_DEFAULT_REGION \
--cluster cruddur \
--task 77777777777777777777777777777 \
--container backend-flask \
--command "/bin/bash" \
--interactive
```

**I received this error:**

`SessionManagerPlugin is not found. Please refer to SessionManager Documentation here: http://docs.aws.amazon.com/console/systems-manager/session-manager-plugin-not-found`

**I then installed the `SessionManagerPlugin`:**

1. Download the bundled installer.

```sh
curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/mac/sessionmanager-bundle.zip" -o "sessionmanager-bundle.zip"
```

2. Unzip the package.

```sh
unzip sessionmanager-bundle.zip
```

3. Run the install command.

```sh
sudo ./sessionmanager-bundle/install -i /usr/local/sessionmanagerplugin -b /usr/local/bin/session-manager-plugin
```

4. Run the following commands to verify that the Session Manager plugin installed successfully.

```sh
session-manager-plugin
```

If the installation was successful, the following message is returned.
```sh
The Session Manager plugin is installed successfully. Use the AWS CLI to start a session.
```

**I still was not able to run 
 ```sh
aws ecs execute-command  \
--region $AWS_DEFAULT_REGION \
--cluster cruddur \
--task 77777777777777777777777777777 \
--container backend-flask \
--command "/bin/bash" \
--interactive
```
to connect to the container since my task deployments kept failing repeatedly in the AWS console. 

![131D2C4E-EDB2-4348-9345-EA9CE93283D5](https://github.com/seekatekode/aws-bootcamp-cruddur-2024/assets/133314947/cdb60503-ad70-416f-90db-da4e3cae915b)

When attaching a shell to the backend container and running `./bin/flask/health-check` I get the results: 

[OK] Flask server is running

But the flask server isn't running, so the container's health status is `Unhealthy`. 
This is the print statement shown in the `health-check` file:

 exit (1)
"[BAD] Flask server is not running"


 CloudWatch log says:
 
 `"error connecting in 'pool-1': connection failed: server closed the connection unexpectedly"`

 
