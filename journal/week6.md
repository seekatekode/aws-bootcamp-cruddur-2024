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

**We then ran the command `/bin/flask/health-check` and it didn't pass the first multiple tries until I stopped the workspace overnight and restarted the same workspace the next morning.** 


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


**We then selected `Compose Up- Select Services`, selected `backend-flask` and `db`, but this was unsuccessful, so we untagged and retagged.  **

** When performing the `health-check` it was successful**


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


