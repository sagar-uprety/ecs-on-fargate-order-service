# ecs-user-lms
Order Microservice for LMS

## Pre-requisite

`dynamodbTableName` and `awsRegion` are used as environment variables. Please refer to Terraform module for creatation of the base-infrastructure.

This microservice calls users and products microservice for creating orders.

`userServiceURL` and `productServiceURL` which reflects the endpoint of the services shall be passed as environment variables to this microservice.

eg. userServiceURL = http://user-service:3000 and productServiceURL= http://product-service:3001
