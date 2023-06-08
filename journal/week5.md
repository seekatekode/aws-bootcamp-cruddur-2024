# Week 5 — DynamoDB and Serverless Caching

## DynamoDB shell commands for this week

   `schema-load`: this creates a table in my `dynamodb-local db`
   
   `list-tables`: after loading my schema, I wrote a script to list my tables
   
   `seed`: add items to ddb table
   
   `drop`: successfully deletes a ddb table when you provide the file name
   
   `scan`: to scan (_return all items in table_) the ddb table
   
   `get-conversations`: will show user's conversations
   
   `list-conversations`: shows user's conversation
   
   `update-cognito-user-ids`: uses the AWS SDK, boto3 to interact with Cognito and obtains the user's `UUID` then updates the user's table with that info.


## **Data Modelling a Direct Messaging System using Single Table Design**

**I identified the necessary data entities, determined their relationships, defined their attributes, and designed a single table schema. I normalized the data to ensure data integrity and tested the model by inserting sample data and running queries to verify that data was stored and retrieved correctly. I changed the usernames to the ones in both of my Cruddur accounts and changing these caused quite a bit of confusion! I had to change the preferred usernames via AWS and this allowed me to not get the accounts mixed up.** 

![Image 5-9-23 at 4 45 PM](https://github.com/kodexkate/aws-bootcamp-cruddur-2023/assets/122316410/d5693adf-58f9-4bfa-881f-5179c93de780)

**Even after running ./bin/db/update_cognito_user_ids the cognito user id was not updating, so it remained to display 'MOCK'. I couldn't figure out why this was not updating,so I decided to return to this issue later.**


![Image 5-9-23 at 5 09 PM](https://github.com/kodexkate/aws-bootcamp-cruddur-2023/assets/122316410/b70a623f-af4f-4678-8d05-2ab74afa9e2d)



**A temp fix for the token error causing the app not to display any messages is due to the message token. I added the this line for the header to the [`MessageGroupsPage.js`], [`MessageGroupPage.js`], and the [`MessageForm.js`]**

```js
headers: {
          Authorization: `Bearer ${localStorage.getItem("access_token")}`
        }
```


**I was finally able to see data on the homepage without any issues.**


![Image 5-9-23 at 5 35 PM](https://github.com/kodexkate/aws-bootcamp-cruddur-2023/assets/122316410/4847158d-f808-4b54-9da0-dc02a6db593e)

![Image 5-9-23 at 4 57 PM](https://github.com/kodexkate/aws-bootcamp-cruddur-2023/assets/122316410/e498071c-1d8f-4fd1-bf4a-851cd9dd4b05)

## Implementing DynamoDB query using Single Table Design

**I identified the required data entities, determined the relationships, defined their attributes, designed a single table schema, created indexes, and implemented the query using the DynamoDB API. The single table design simplified the data structure and made it easier to manage indexes, resulting in improved query performance.** 

- **I replaced codes in;**

`backend-flask/app.py` (mainly, instead of using `"/api/messages/@<string:handle>"`, use `"/api/messages/<string:message_group_uuid>"`)

`backend-flask/services/message_groups.py`

`backend-flask/services/messages.py`


**I created and changed codes in;**

Created `backend-flask/db/sql/users/uuid_from_cognito_user_id.sql`

Changed `backend_url` from using `${handle}` to `${params.message_group_uuid}` in `frontend-react-js/src/pages/MessageGroupPage.js`

Changed path from `"/messages/@:handle"` to `"/messages/:message_group_uuid"` in `frontend-react-js/src/App.js`

Change `params.handle` to `params.message_group_uuid` and `props.message_group.handle` to `props.message_group.uuid` in `frontend-react-js/src/components/MessageGroupItem.js`


**For this week I updated the code to the frontend file:**

created `frontend-react-js/src/lib/CheckAuth.js` 

`frontend-react-js/src/pages/HomeFeedPage.js`

`frontend-react-js/src/pages/MessageGroupPage.js`

`frontend-react-js/src/pages/MessageGroupsPage.js`

`frontend-react-js/src/components/MessageForm.js`

Updated the content for `body` in `frontend-react-js/src/components/MessageForm.js`

Updated function `data_create_message` in `backend-flask/app.py`

Updated `backend-flask/services/create_message.py` 

Created `backend-flask/db/sql/users/create_message_users.sql`

Imported `MessageGroupNewPage` from `./pages/MessageGroupNewPage` and add the corresponding router in `frontend-react-js/src/App.js`

Created `frontend-react-js/src/pages/MessageGroupNewPage.js`

Created `frontend-react-js/src/components/MessageGroupNewItem.js`

Add the endpoint and function for user short in `backend-flask/app.py`

Created `backend-flask/services/users_short.py`

Created `backend-flask/db/sql/users/short.sql`

Updated `frontend-react-js/src/components/MessageGroupFeed.js`

Updated `frontend-react-js/src/components/MessageForm.js`

Updated `list-conversations` and `get-conversation`

Updated `ddb.py` 

**I was having issues with loading the Messages page, but when viewing the frontend logs I couldn't figure out what the issue was, so I inspected the page and found that `set user` was not defined in my `MessageGroupsPage.js`. I updated this file and the Messages page finally loaded!**


![Image 5-11-23 at 11 20 AM](https://github.com/kodexkate/aws-bootcamp-cruddur-2023/assets/122316410/147123e2-f91d-4b53-97d7-0ebd207572d2)


## Provisioning DynamoDB tables with Provisioned Capacity

**I identified the table's required read and write capacity and set the provisioned capacity accordingly. I monitored the table's capacity usage and adjusted it as needed to maintain optimal performance. Provisioning capacity enabled me to ensure that the table could handle the required traffic and maintain low latency.**


## Utilizing a Global Secondary Index (GSI) with DynamoDB

**I identified the table's access patterns and created a GSI that would enable me to query the data efficiently based on specific attributes. I configured the GSI to include the required attributes and provisioned read and write capacity to handle the expected traffic. I then tested the GSI by running queries and verified that the results were correct. The GSI allowed me to access the data quickly and reduced the complexity of the query process.**

## Rapid data modelling and implementation of DynamoDB with DynamoDB Local

 **I identified the required data entities, their relationships, and defined their attributes. I then designed a single table schema that would enable me to store and retrieve the data efficiently. I used DynamoDB Local to create a local development environment, which allowed me to test the data model and implementation without incurring any costs. I inserted sample data and ran queries to verify that data was stored and retrieved correctly.**


## Writing utility scripts to easily setup and teardown and debug DynamoDB data

**I identified the required scripts, including scripts to create tables, insert sample data, query data, and delete tables. I used the AWS SDK to interact with DynamoDB and implemented error handling and logging to aid in debugging. The utility scripts allowed me to automate the setup and teardown process and enabled me to easily test and debug the data model and implementation.**

 **I encountered several issues while working on my project, but I managed to overcome them through perseverance and problem-solving. Here's a summary of the challenges I faced and the solutions I implemented:**
 
 **1. Issue:** `Cognito JWT Token` and `Cognito User ID`
Description: I encountered difficulties retrieving the Cognito JWT token and Cognito User ID required for authentication and authorization.
Solution: After careful examination of the AWS Cognito documentation and troubleshooting, I was able to successfully retrieve the necessary Cognito JWT token and Cognito User ID by implementing the appropriate API calls and configurations.

**2. Issue:** `./bin/db/update_cognito_user_ids`
Description: When running the ./bin/db/update_cognito_user_ids command, I received an error message stating that the original AWS_SECRET_ACCESS_KEY and AWS_ACCESS_KEY_ID were no longer valid.
**Solution:** Upon investigation, I discovered that the issue arose due to special characters present in the AWS_SECRET_ACCESS_KEY. To resolve this, I regenerated a new AWS_SECRET_ACCESS_KEY without any special characters, allowing me to successfully run the update command and retrieve the desired results.

**3. Issue:** `./bin/db/seed` and `./bin/ddb/seed`
Description: I encountered difficulties with the ./bin/db/seed and ./bin/ddb/seed scripts, resulting in errors during the data seeding process.
**Solution:** To overcome these issues, I carefully reviewed the seed scripts and identified the syntax errors that were causing the problems. After making the necessary corrections, I successfully ran the scripts, ensuring the proper seeding of the required data.

**4. Issue:** `Londo's Message Not Appearing`
Description: After running the INSERT INTO public.users command to import messages, I noticed that Londo's message was not appearing as expected.
**Solution:** By clearing the message group UUID from the URL and appending /messages/new/londo to the frontend address, I was able to access the message creation page specifically for Londo. Sending a message from there helped import Londo's message above the other user's message, resolving the issue.



