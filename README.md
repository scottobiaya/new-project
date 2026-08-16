AWS Terraform Docker Deployment

This project provisions an AWS environment using Terraform and deploys a containerised Nginx application on two EC2 instances.

Terraform creates the AWS infrastructure, including the VPC, subnets, security group, EC2 instances, and Application Load Balancer.

When the EC2 instances start, they install Docker and pull the existing application image from Docker Hub:

scottobiaya/scott-nginx-app:2.1

The Docker image is not built on the EC2 instances. It is pulled from Docker Hub and then run as a container.

Architecture
flowchart TB

    User((User / Browser))

    User -->|HTTP :80| ALB["Application Load Balancer"]

    subgraph AWS["AWS"]
        subgraph VPC["VPC"]

            ALB -->|HTTP :80| EC1["EC2 Instance 1<br/>us-east-1a"]
            ALB -->|HTTP :80| EC2["EC2 Instance 2<br/>us-east-1b"]

            EC1 --> D1["Docker Container<br/>Nginx"]
            EC2 --> D2["Docker Container<br/>Nginx"]

        end
    end

    DockerHub["Docker Hub<br/>scottobiaya/scott-nginx-app:2.1"]

    EC1 -.->|docker pull| DockerHub
    EC2 -.->|docker pull| DockerHub
How the Deployment Works

The deployment has two separate parts:

1. Infrastructure

Terraform creates and configures the AWS resources.

The infrastructure includes:

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
2. Application

The application is packaged as a Docker image and stored in Docker Hub.

The EC2 instances do not build the image.

During startup, each EC2 instance:

Updates the Ubuntu package repository.
Installs Docker.
Starts the Docker service.
Pulls scottobiaya/scott-nginx-app:2.1 from Docker Hub.
Starts the Docker container.
Passes the server-specific message into the container.
Nginx serves the web page on port 80.

The Application Load Balancer then distributes requests between the two EC2 instances.

Deployment Flow
                         User
                           |
                           | HTTP
                           v
                Application Load Balancer
                     /             \
                    /               \
                   v                 v
             EC2 Instance 1     EC2 Instance 2
             us-east-1a         us-east-1b
                   |                 |
                   v                 v
                Docker            Docker
                   |                 |
                   v                 v
             Nginx Container    Nginx Container
                   ^                 ^
                   |                 |
                   +--------+--------+
                            |
                       docker pull
                            |
                            v
                       Docker Hub
                            |
                            v
              scottobiaya/scott-nginx-app:2.1
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

The main.tf file defines the AWS infrastructure.

It creates:

VPC
Public subnets
Internet Gateway
Route table
Security group
EC2 instances
Application Load Balancer
Target group
Listener
Target group attachments

The two EC2 instances are deployed in different Availability Zones:

EC2 Instance 1 → us-east-1a
EC2 Instance 2 → us-east-1b

This allows the Load Balancer to distribute traffic between two separate instances.

variables.tf

The project uses Terraform variables for values that need to be configurable.

Current variables include:

cidr_block
key_name

The Docker image is not defined as a Terraform variable in this version of the project.

The Docker image is specified directly in server-setup.sh:

scottobiaya/scott-nginx-app:2.1
EC2 Server Setup

The scripts/server-setup.sh file is used as EC2 user data.

Terraform passes a different SERVER_MESSAGE to each EC2 instance.

For the first instance:

SERVER_MESSAGE = "scott server 1"

For the second instance:

SERVER_MESSAGE = "scott server 2"

The setup script then passes this value into the Docker container.

The relevant Docker command is:

docker run -d \
  --name scott-nginx \
  --restart unless-stopped \
  -p 80:80 \
  -e SERVER_MESSAGE="${SERVER_MESSAGE}" \
  scottobiaya/scott-nginx-app:2.1

This allows both servers to run the same Docker image while displaying a different server message.

Docker Image

The Docker image used by the EC2 instances is:

scottobiaya/scott-nginx-app:2.1

The image is hosted on Docker Hub.

The EC2 instances retrieve it using:

docker pull scottobiaya/scott-nginx-app:2.1

The image contains the Nginx application and its startup configuration.

The Docker image is therefore separate from the Terraform infrastructure.

Docker on the Local Machine

Docker is not required on the local Windows machine to deploy this infrastructure.

Terraform is used locally to provision the AWS resources.

Docker is installed automatically on the EC2 instances by server-setup.sh.

The deployment therefore works as follows:

Local Windows Machine
        |
        | terraform apply
        v
       AWS
        |
        v
    EC2 Instance
        |
        | install Docker
        |
        | docker pull
        v
    Docker Hub
        |
        v
   Docker Container
        |
        v
       Nginx
Prerequisites

The following are required on the machine running Terraform:

AWS account
AWS CLI
Terraform
Git
GitHub account
AWS credentials
An existing Docker image on Docker Hub

Docker is not required locally for the current deployment process.

The Docker image used by the EC2 instances must already exist in Docker Hub.

AWS Credentials

Before running Terraform, configure AWS credentials.

Verify the current AWS identity:

aws sts get-caller-identity

The command should return information about the AWS account and identity being used.

Deployment

Clone the repository:

git clone https://github.com/scottobiaya/new-project.git

Move into the project directory:

cd new-project

Initialise Terraform:

terraform init

Format the Terraform configuration:

terraform fmt

Validate the configuration:

terraform validate

Create a deployment plan:

terraform plan

Apply the configuration:

terraform apply

Review the resources Terraform plans to create and confirm the deployment.

Checking the EC2 Instances

After Terraform creates the instances, connect to an EC2 instance using SSH:

ssh -i <key-file> ubuntu@<EC2-PUBLIC-IP>

Check that Docker is running:

sudo systemctl status docker

Check the running container:

sudo docker ps

Check the Docker image:

sudo docker images

The expected image is:

scottobiaya/scott-nginx-app

Check the container logs:

sudo docker logs scott-nginx
Testing Nginx

From an EC2 instance, test the local container:

curl http://localhost

The response should contain the server-specific message.

For example, the first instance should display:

scott server 1

and the second instance should display:

scott server 2
Testing Through the Load Balancer

The Application Load Balancer provides the public entry point for the application.

After Terraform creates the Load Balancer, obtain its DNS name from the AWS console.

Open the following in a browser:

http://<LOAD-BALANCER-DNS-NAME>

The Load Balancer forwards the request to one of the EC2 instances.

Refreshing the page may return a response from either instance.

This demonstrates that the Application Load Balancer is distributing traffic between the two EC2 instances.

Terraform State

Terraform maintains information about the infrastructure in its state file.

Terraform state files should not be committed to GitHub.

The .gitignore file should contain entries similar to:

.terraform/
*.tfstate
*.tfstate.*
*.tfplan
tfplan

Terraform plan files should also remain outside the Git repository.

Updating the Docker Application

The current Terraform deployment uses the existing Docker Hub image:

scottobiaya/scott-nginx-app:2.1

If the application is changed, a new Docker image must be built and pushed to Docker Hub before the EC2 instances can use it.

For example, a future version could use:

scottobiaya/scott-nginx-app:2.2

The EC2 startup configuration would then need to be updated to pull and run the new image.

Docker is not currently installed on the Windows development machine, so building new images would need to be performed from another environment that has Docker installed.

Destroying the Infrastructure

When the environment is no longer required, the AWS resources can be removed using:

terraform destroy

Review the resources Terraform plans to remove before confirming the operation.

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

This project demonstrates how Terraform can be used to provision AWS infrastructure and deploy a Dockerised application.

Terraform manages the infrastructure while Docker manages the application runtime.

The final deployment separates the two responsibilities:

Terraform
    |
    v
AWS Infrastructure
    |
    +-- VPC
    |
    +-- Subnet 1
    |      |
    |      +-- EC2
    |           |
    |           +-- Docker
    |                |
    |                +-- Nginx
    |
    +-- Subnet 2
    |      |
    |      +-- EC2
    |           |
    |           +-- Docker
    |                |
    |                +-- Nginx
    |
    +-- Application Load Balancer

Docker Hub
    |
    +-- scottobiaya/scott-nginx-app:2.1
             |
             +-- pulled by EC2 Instance 1
             |
             +-- pulled by EC2 Instance 2

The result is a repeatable AWS deployment where Terraform provisions the infrastructure and the EC2 instances retrieve the application container from Docker Hub.