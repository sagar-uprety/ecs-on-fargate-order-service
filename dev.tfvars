################################################################################
# Input local variables
################################################################################

service        = "order"
container_name = "order"
container_port = "3002"
imageurl       = "426857564226.dkr.ecr.us-east-2.amazonaws.com/lms-order-ms:latest"
environment    = "dev"
application    = "order-service"
owner          = "adex-lms"
region         = "us-east-2"
