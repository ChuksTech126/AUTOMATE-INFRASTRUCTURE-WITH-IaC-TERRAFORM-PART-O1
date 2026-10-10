# AWS Infrastructure Automation with Terraform

### Building Secure Cloud Foundations Through Infrastructure as Code

## Project Overview

This project documents my practical journey into **Infrastructure as Code (IaC) using Terraform and Amazon Web Services (AWS)**. My goal was to understand not only how to provision cloud resources, but also how identity, access management, state management, security, and networking work together in a cloud environment.

I began by configuring AWS access for my local development environment, verified access using Python and Boto3, and then progressed to provisioning an S3 bucket with security features, migrating Terraform state to remote storage, and building a configurable VPC networking foundation.

Along the way, I encountered errors, investigated their causes, and refined my understanding of Terraform resource relationships and AWS networking.

This project represents an important step in moving from manually managing cloud resources toward **automating infrastructure through code**.

## Project Objectives

- Establish programmatic access to AWS from a local development machine.
- Understand IAM users, groups, permissions, and access keys.
- Verify AWS access using Python and Boto3.
- Provision a secure S3 bucket using Terraform.
- Configure remote Terraform state storage and migrate existing local state.
- Build a VPC with dynamically created subnets.
- Retrieve Availability Zone information using Terraform data sources.
- Configure an Internet Gateway, route table, and subnet associations.
- Develop practical troubleshooting and infrastructure validation skills.

## Technologies Used

| Technology | Purpose |
|---|---|
| Amazon Web Services (AWS) | Cloud infrastructure platform |
| AWS IAM | Identity and access management |
| AWS CLI | Local programmatic access to AWS |
| Python and Boto3 | AWS access verification |
| Terraform | Infrastructure provisioning and state management |
| Amazon S3 | Remote Terraform state storage |
| Amazon VPC | Virtual networking |
| Internet Gateway | Internet routing for the VPC |
| PowerShell | Running commands from the local Windows environment |

## Project Implementation

### 1. Configuring AWS Identity and Access Management

Before provisioning infrastructure, I prepared my AWS environment for programmatic access.

Using the AWS Management Console, I:

1. Created an IAM user.
2. Added the user to an IAM group to manage permissions through group membership.
3. Created an access key ID and secret access key for programmatic access.
4. Configured my local machine to authenticate with AWS using those credentials.

This introduced me to the relationship between AWS identities, permissions, and programmatic authentication.

![](/images/PBL/user&group.png)

![](/images/PBL/aws-configure.png)

**Key lesson:** An access key authenticates programmatic requests, but permissions determine which AWS operations the identity is authorized to perform. Following least-privilege principles is essential when configuring IAM users and groups.

For real-world environments, IAM roles and temporary credentials are generally preferable to long-lived access keys where applicable.

### 2. Verifying AWS Access with Python and Boto3

After configuring local AWS access, I used **Boto3**, the AWS SDK for Python, to verify that my local environment could communicate with AWS.

This step helped me understand that AWS resources can be accessed through more than the management console or Terraform. Applications and automation scripts can also interact with AWS APIs using appropriately configured credentials and permissions.

The verification stage established a useful baseline before moving on to infrastructure provisioning.

![](/images/pbl/pip-boto.png)

![](/images/PBL/python-bucket.png)

**What I learned:**
- How local AWS credentials support programmatic access.
- How Python can interact with AWS services through Boto3.
- Why valid authentication and appropriate IAM permissions are both necessary.
- How to verify connectivity before proceeding with automation.

### 3. Provisioning an S3 Bucket with Terraform

With AWS access configured, I moved on to creating an Amazon S3 bucket using Terraform.

Rather than stopping at bucket creation, I configured additional controls to improve data protection.

The bucket includes:

- **Versioning:** Preserves multiple versions of objects, supporting recovery from certain accidental changes or deletions.
- **Server-side encryption:** Uses AES-256 encryption for stored objects.
- **Public access restrictions:** Configures S3 Block Public Access settings to help prevent unintended public exposure.

![](/images/PBL/s3.png)

This stage introduced me to defining infrastructure declaratively, where the desired configuration is expressed in code rather than created entirely through manual console operations.


### 4. Migrating Terraform State to Remote Storage

After creating the S3 bucket, I configured it as the Terraform backend and migrated my existing state from local storage to the remote backend.

Terraform state is important because it records information about the resources managed by a configuration and helps Terraform determine what changes are required.

By moving the state to S3, I gained practical experience with centralized state storage and learned how backend configuration fits into the Terraform workflow.

I also enabled S3-based state locking with:

```hcl
use_lockfile = true
```

This allows Terraform to use a lock file to coordinate state operations and reduce the risk of concurrent modifications.

**Key lesson:** The backend bucket must exist before Terraform can initialize against it. The state file should also be treated as sensitive information, with access controlled through appropriate IAM permissions.

### 5. Creating a Virtual Private Cloud

I then created an Amazon VPC to establish an isolated virtual network for the infrastructure.

The VPC uses a configurable CIDR block, while DNS support and DNS hostnames are controlled through Terraform variables.

Using variables makes the configuration more flexible and reduces the need to hardcode values throughout the project.

![](/images/PBL/vpc.png)

This stage helped me understand how Terraform variables can make infrastructure easier to adapt to different requirements.

### 6. Dynamically Creating Subnets

Instead of manually declaring each subnet in a separate resource block, I used Terraform's `count` argument, `length()` function, and conditional expressions.

I also used the `aws_availability_zones` data source to retrieve the Availability Zones available to the AWS account and region.

The configuration uses this information to select Availability Zones for subnet placement.

This approach reduces repetitive code and allows the number of subnets to be adjusted through a variable.

````hcl
data "aws_availability_zones" "existing_Azs" {
  state = "available"
}

resource "aws_subnet" "chuks_subnet" {
  vpc_id                  = aws_vpc.chuks_vpc.id
  count                   = var.preferred_number_of_subnets == null ? length(data.aws_availability_zones.existing_Azs.names) : var.preferred_number_of_subnets
  cidr_block              = cidrsubnet(var.cidr_block, 8, count.index)
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.existing_Azs.names[count.index]
  tags = {
    Name = "public_subnet ${count.index + 1}"
  }
}
````

**Key concepts practiced:**
- Terraform data sources.
- Conditional expressions.
- Dynamic resource creation with `count`.
- Indexing with `count.index`.
- References between dependent resources.

The number of subnets created depends on the configured variable or the number of available Availability Zones returned by the data source.

### 7. Understanding Public Subnet Configuration

One of the most important learning moments came when I examined the difference between assigning public IP addresses and configuring a subnet for internet connectivity.

Initially, I configured:

```hcl
map_public_ip_on_launch = true
```

This setting enables automatic public IPv4 address assignment for instances launched into the subnet, where supported.

However, I realized that this setting alone does not make a subnet public.

A public subnet also requires a route to an Internet Gateway. Instances must additionally have appropriate public addressing, security rules, and services configured to permit the intended communication.

This distinction helped me understand AWS networking beyond simply creating resources.

### 8. Creating and Attaching an Internet Gateway

To establish an internet-routing path, I created an Internet Gateway and attached it to the VPC.

The Internet Gateway provides a connection between the VPC and the public internet when the necessary routes and access controls are configured.

````hcl
resource "aws_internet_gateway" "chuks_gateway" {
  vpc_id = aws_vpc.chuks_vpc.id

  tags = {
    Name = var.aws_internet_gateway
  }
}
````

![](/images/PBL/IGW.png)

This step helped me understand how a VPC's routing configuration determines whether traffic can reach destinations outside the network.

### 9. Configuring the Route Table

Next, I created a route table associated with the VPC and configured a default IPv4 route:

```hcl
cidr_block = "0.0.0.0/0"
```


````hcl
resource "aws_route_table" "chuks_route_table" {
  vpc_id = aws_vpc.chuks_vpc.id

  route {
    gateway_id = aws_internet_gateway.chuks_gateway.id
    cidr_block = "0.0.0.0/0"
  }
  tags = {
    Name = var.aws_route_table
  }
}

````

![](/images/PBL/chuks-rt.png)

The route directs traffic that does not match a more specific route toward the Internet Gateway.

This creates the routing path required for internet connectivity from subnets associated with the route table.

The presence of this route does not automatically make every resource publicly accessible; access still depends on addressing and security configuration.

### 10. Dynamically Associating Subnets with the Route Table

Because the subnet resources were created dynamically, I used `aws_route_table_association` with `count` and `count.index` to associate each subnet with the route table.

````hcl
resource "aws_route_table_association" "chuks_route_table_subnet_association" {
  count          = length(aws_subnet.chuks_subnet)
  subnet_id      = aws_subnet.chuks_subnet[count.index].id
  route_table_id = aws_route_table.chuks_route_table.id
}
````
![](/images/PBL/asso.png)

This approach allows multiple subnet associations to be created from a single resource definition rather than writing a separate block for every subnet.

It also gave me practical experience troubleshooting Terraform errors. I learned that resource types must match the AWS provider's supported resource names and that `count.index` can only be used in a block where `count` is declared.

This was a useful reminder that successful Infrastructure as Code development involves understanding the relationships between resources, not just writing configuration syntax.

## Architecture Summary

The resulting configuration establishes the following logical structure:

```text
Local Development Machine
          |
          | IAM credentials
          v
       AWS Access
          |
          +------ Boto3 verification
          |
          +------ Terraform
                    |
                    +------ S3 bucket
                    |        +-- Versioning
                    |        +-- Encryption
                    |        +-- Public access restrictions
                    |        +-- Remote Terraform state
                    |
                    +------ VPC
                             |
                             +-- Dynamically created subnets
                             |
                             +-- Internet Gateway
                             |
                             +-- Route table
                                      |
                                      +-- Subnet associations
```

![](/images/PBL/overview-image.png)

This illustrates the main components implemented and the desired state achieved in the project. The S3 backend and VPC networking are separate parts of the configuration: the backend stores Terraform state, while the VPC provides the network foundation.

## Challenges and Lessons Learned

This project was not only about creating resources; it was also about understanding why they work.

Some of the key lessons came from troubleshooting:

- **Provider errors:** I learned that Terraform resource types must use the correct provider-specific names.
- **Dynamic associations:** I learned to use `count` and `count.index` correctly when associating multiple subnets with a route table.
- **Remote state:** I gained a clearer understanding of the role of the backend and the importance of migrating existing state carefully.
- **Subnet routing:** I learned why automatic public IP assignment alone is insufficient to establish internet connectivity.
- **Configuration design:** I practiced using variables and data sources to reduce hardcoding and improve flexibility.

Working through these issues helped me connect Terraform syntax with the underlying AWS infrastructure.

## Validation Workflow

Throughout the project, Terraform's validation and planning commands were useful for identifying configuration issues before making infrastructure changes.

```powershell
terraform init
terraform validate
terraform plan
terraform apply
```

- `terraform init` initializes the backend and installs required providers.
  
  ![](/images/PBL/backed-init.png)

- `terraform validate` checks configuration syntax and consistency.

![](/images/PBL/validate.png)

- `terraform plan` previews the proposed infrastructure changes.

![](/images/PBL/plan-1.png)

The plan should always be reviewed before applying changes, particularly when managing existing cloud resources or remote state.

- `terraform apply` provisions or updates resources according to the approved plan.

![](/images/PBL/apply-01.png)

![](/images/PBL/apply-02.png)

![](/images/PBL/apply-03.png)

![](/images/PBL/apply-04.png) 

![](/images/PBL/apply-05.png)

## Desired and achieved State

![](/images/PBL/overview-image.png)


## Security Considerations

Security remains an important part of infrastructure automation.

For this project, I configured S3 encryption and public access restrictions, and used IAM group membership to manage permissions for programmatic access.

Further improvements for production environments would include:

- Using least-privilege IAM policies.
- Preferring temporary credentials and IAM roles where appropriate.
- Never committing access keys, secret keys, Terraform state files, or other sensitive values to Git.
- Restricting access to the S3 backend.
- Reviewing security group and network ACL rules before deploying workloads.
- Separating public and private subnets when required.
- Planning for state recovery, monitoring, and operational security.

A route to an Internet Gateway should never be interpreted as a reason to permit unrestricted inbound traffic.

## Future Improvements

This project provides a foundation for more advanced AWS automation. Potential next steps include:

- Deploying EC2 instances into the VPC.
- Configuring security groups with restricted inbound rules.
- Separating public, and/or add private subnets.
- Adding NAT Gateway connectivity for private workloads that require outbound internet access.
- Organizing resources into reusable Terraform modules.
- Integrating Terraform validation and deployment into a CI/CD pipeline.
- provision EKS using Terraform
- Improving remote-state access management and recovery procedures.

## Conclusion

This project has helped me develop a more practical understanding of AWS and Infrastructure as Code.

From configuring IAM access and verifying AWS connectivity with Boto3 to provisioning secure S3 storage, migrating Terraform state, and building dynamic VPC networking, each stage introduced a concept that connects to the next.

One of my biggest takeaways is that cloud infrastructure is not simply a collection of resources. It is a system of identities, permissions, state, networking, and dependencies that must be configured to work together.

I am continuing to build on these foundations as I progress toward more advanced cloud infrastructure automation and DevOps projects.

**Technologies:** AWS IAM | Python | Boto3 | Terraform | Amazon S3 | Amazon VPC | Internet Gateway | Route Tables | Infrastructure as Code
