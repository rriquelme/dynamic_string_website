# Solution
The solution implemented to approach the challenge is to use a API Gateway and a Lambda function to display the html website, and for storing the dynamic string, the Parameter Store is used. The same Lambda function is also used to update the Parameter Store.

![Implemented Solution Diagram](ImplementedSolution.png)

## How to view and update the html page:

At the end of the terraform execution (```terraform apply```) the output will show the URL of the deployment, i.e.

```terraform
Outputs:

URL = "https://<Chars>.execute-api.us-east-1.amazonaws.com/prod"

```
To update the dynamic string it is necessary to update add a parameter to the url, the parameter 'newstring' i.e.
```html
https://<Chars>.execute-api.us-east-1.amazonaws.com/prod?newstring=New String
```

This will update the website and all users will see "New String" on the website.

## Why this solution was chosen
This solution was chosen by simplicity, only a few serverless resources deployed, and for user usability, the same url is used to update the dynamic string.

## Other solutions
Direct solutions to this challenge can be obtained used a similar topology:
- Using any database capable of storing a string and able to communicate with lambda.

![Diagram Any DB](OtherSolutionAnyDB.png)

- Using S3 for static website and Lambda to update the static website.

![Diagram S3](OtherSolutionS3.png)

Other Solutions:
- Using an EC2 with internet access, configuring django, with a local or remote db.

- Using a EC2 with any variation of apache/nginx and modify the files directly

- Using ECS/EKS to store a container to do the same as the previous bullet but containerized.


## How to improve the solution
- Add Cloudfront in front the API Gateway and then add WAF, so it can be protected from DDOS, to avoid extra costs.

- If the solution needs more speed, change the Parameter Store for a database, i.e. DynamoDB.

- Add some cache to avoid calling too much the lambda functions.

- If the solution grows and need a better website, go to the EC2/lightsail/ECS solutions with external DB.

- For the repository, enable github actions to deploy the solution after a PR approve.

- For the terraform state file, store it into S3 to avoid loosing it.

---
@Author: rriquelme