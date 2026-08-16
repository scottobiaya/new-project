AWS Terraform Docker Nginx Deployment

This project provisions AWS infrastructure with Terraform and runs an Nginx application inside Docker containers on two EC2 instances.

Terraform creates the network, EC2 instances, security group, Application Load Balancer, target group and listener.

The application image is already stored in Docker Hub:

scottobiaya/scott-nginx-app:2.1

When the EC2 instances are launched, server-setup.sh installs Docker, pulls the image from Docker Hub and starts the container.

Docker is not installed on the local Windows machine. The EC2 instances handle the Docker runtime.

Architecture
flowchart TB

    Internet((Internet))

    subgraph AWS["AWS"]
        subgraph VPC["VPC 10.0.0.0/16"]

            IGW["Internet Gateway"]

            subgraph PublicSubnets["Public Subnets"]
                
                subgraph AZ1["us-east-1a"]
                    EC2A["EC2 Instance 1"]
                    CONTA["Docker Container<br/>Nginx"]
                    EC2A --> CONTA
                end

                subgraph AZ2["us-east-1b"]
                    EC2B["EC2 Instance 2"]
                    CONTB["Docker Container<br/>Nginx"]
                    EC2B --> CONTB
                end

            end

            ALB["Application Load Balancer<br/>HTTP :80"]

            ALB --> EC2A
            ALB --> EC2B

        end
    end

    Internet --> IGW
    IGW --> ALB

    DockerHub[("Docker Hub<br/>scottobiaya/scott-nginx-app:2.1")]

    DockerHub -. "docker pull" .-> EC2A
    DockerHub -. "docker pull" .-> EC2B
How It Works

The deployment is split into two parts.

Infrastructure

Terraform provisions the AWS environment:

VPC
Two public subnets
Internet Gateway
Public route table
Security group
Two EC2 instances
Application Load Balancer
Target group
Load Balancer listener
Target group attachments

The EC2 instances are placed in separate Availability Zones:

Instance	Availability Zone	Subnet
EC2 Instance 1	us-east-1a	10.0.1.0/24
EC2 Instance 2	us-east-1b	10.0.2.0/24
Application

The Docker image is stored in Docker Hub and is pulled by each EC2 instance when it starts.

The image contains Nginx and the application startup script.

The EC2 instances do not build the image during Terraform deployment.

Deployment Flow
sequenceDiagram
    participant T as Terraform
    participant A as EC2 Instance 1
    participant B as EC2 Instance 2
    participant D as Docker Hub
    participant L as Load Balancer
    participant U as User

    T->>A: Launch instance and run user_data
    T->>B: Launch instance and run user_data

    A->>A: Install Docker
    B->>B: Install Docker

    A->>D: Pull scott-nginx-app:2.1
    D-->>A: Docker image

    B->>D: Pull scott-nginx-app:2.1
    D-->>B: Docker image

    A->>A: Start Nginx container
    B->>B: Start Nginx container

    U->>L: HTTP request
    L->>A: Forward request
    A-->>L: HTTP response
    L-->>U: Response
Project Structure
New-Project/
│
├── docker/
│   ├── Dockerfile
│   └── start.sh
│
├── scripts/
│   └── server-setup.sh
│
├── .gitignore
├── .terraform.lock.hcl
├── README.md
├── main.tf
├── provider.tf
└── variables.tf
Terraform Configuration
main.tf

main.tf contains the AWS infrastructure configuration.

The file creates the VPC, subnets, routing, security group, EC2 instances and Application Load Balancer.

The two EC2 instances use the same startup script but receive different server messages.

Instance 1:

SERVER_MESSAGE = "scott server 1"

Instance 2:

SERVER_MESSAGE = "scott server 2"

Terraform passes these values to server-setup.sh using templatefile().

variables.tf

The project currently uses two Terraform variables:

variable "cidr_block" {
  type    = string
  default = "10.0.0.0/16"
}

variable "key_name" {
  type    = string
  default = "terraform-ec2-key"
}

The Docker image is not a Terraform variable.

The image name and version are currently defined in server-setup.sh:

scottobiaya/scott-nginx-app:2.1
Docker

The Docker configuration is located in the docker directory.

Dockerfile

The Dockerfile uses the Nginx base image:

FROM nginx:latest

It copies start.sh into the image and uses the script as the container startup command.

The Dockerfile is used when the Docker image is built.

start.sh

start.sh runs inside the Docker container.

It creates the Nginx index.html file using the SERVER_MESSAGE environment variable and then starts Nginx.

The important distinction is that start.sh belongs to the Docker image. It is not the script used to configure the EC2 server.

EC2 Server Setup

The EC2 instances are configured using:

scripts/server-setup.sh

Terraform passes the script to each EC2 instance through user_data.

The script performs the following tasks:

Updates the Ubuntu package repository.
Installs Docker and curl.
Enables Docker.
Starts Docker.
Pulls the Docker image from Docker Hub.
Starts the Nginx container.
Checks that the container is running.
Tests the application locally with curl.

The Docker image used is:

scottobiaya/scott-nginx-app:2.1

The container is started with:

docker run -d \
  --name scott-nginx \
  --restart unless-stopped \
  -p 80:80 \
  -e SERVER_MESSAGE="${SERVER_MESSAGE}" \
  scottobiaya/scott-nginx-app:2.1
Docker Image and EC2 Deployment

The application image is maintained separately from the Terraform infrastructure.

The relationship between the Docker image and EC2 deployment is:

flowchart LR

    Image["Docker Image<br/>scott-nginx-app:2.1"]

    Registry[("Docker Hub")]

    EC1["EC2 Instance 1"]
    EC2["EC2 Instance 2"]

    C1["Nginx Container"]
    C2["Nginx Container"]

    Image --> Registry
    Registry -.-> EC1
    Registry -.-> EC2

    EC1 --> C1
    EC2 --> C2

The EC2 instances only need access to Docker Hub to retrieve the image.

Local Development Environment

Docker is not installed on the local Windows machine used for this project.

This does not prevent the Terraform deployment.

Terraform is run locally and provisions the AWS resources. Docker is installed automatically on the EC2 instances by server-setup.sh.

The current deployment therefore does not require a local Docker installation.

Prerequisites

The following are required:

AWS account
AWS CLI
Terraform
Git
GitHub account
AWS credentials
Docker image available in Docker Hub

Docker is not required on the local machine for the current deployment.

AWS Credentials

Configure AWS credentials before running Terraform.

Verify the configured AWS identity:

aws sts get-caller-identity

The command should return the AWS account and IAM identity being used.

Deployment

Clone the repository:

git clone https://github.com/scottobiaya/new-project.git

Move into the project directory:

cd new-project

Initialise Terraform:

terraform init

Format the Terraform files:

terraform fmt

Validate the configuration:

terraform validate

Create a Terraform plan:

terraform plan

Apply the configuration:

terraform apply

Review the resources Terraform plans to create before confirming the deployment.

Checking the EC2 Instances

Connect to an EC2 instance using SSH:

ssh -i <key-file> ubuntu@<EC2-PUBLIC-IP>

Check the Docker service:

sudo systemctl status docker

Check the running container:

sudo docker ps

Check the downloaded image:

sudo docker images

Check the application logs:

sudo docker logs scott-nginx
Testing the Application

Test the application directly from an EC2 instance:

curl http://localhost

The first EC2 instance should return its configured message:

scott server 1

The second EC2 instance should return:

scott server 2

This confirms that both instances are running the same Docker image while receiving different SERVER_MESSAGE values.

Testing Through the Load Balancer

The Application Load Balancer provides the public endpoint for the application.

Find the Load Balancer DNS name in the AWS console.

Open:

http://<LOAD-BALANCER-DNS-NAME>

The Load Balancer forwards requests to the registered EC2 instances.

Because the two instances have different server messages, refreshing the page can show which backend instance handled the request.

Terraform State

Terraform state files contain information about the infrastructure and should not be committed to GitHub.

The .gitignore file should include:

.terraform/
*.tfstate
*.tfstate.*
*.tfplan
tfplan

Terraform plan files should also remain outside the repository.

Updating the Application

The current deployment uses:

scottobiaya/scott-nginx-app:2.1

If the application is changed, a new Docker image needs to be built and pushed to Docker Hub.

For example:

scottobiaya/scott-nginx-app:2.2

The EC2 startup configuration would then need to reference the new image version.

The current Windows development machine does not have Docker installed, so a Docker-enabled environment would be required to build and publish a new image.

Destroying the Infrastructure

When the environment is no longer required:

terraform destroy

Review the resources that Terraform plans to remove before confirming the operation.

Technologies Used
AWS
Terraform
Amazon EC2
Application Load Balancer
Docker
Docker Hub
Nginx
Ubuntu Linux
Git
GitHub
Project Summary

This project demonstrates a basic Infrastructure as Code deployment using Terraform and Docker.

Terraform manages the AWS infrastructure while Docker provides the application runtime on the EC2 instances.

The application image is stored in Docker Hub and is pulled by the EC2 instances during startup.

The final setup consists of two EC2 instances running the same Nginx Docker image behind an Application Load Balancer.