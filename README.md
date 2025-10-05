# Dynamic String Website
This repository is the solution to the dynamic string html challenge requested.

## Folder Structure
- **terraform/**: all terraform files needed to implement the solution
- **terraform/lambda/app.py**: Lambda Python file to be deployed, runs on Python 3.13
- **docs/**: Documentation files.

## How to use this repository:
1. Configure & install AWS CLI
2. Configure & install Terraform
3. Clone repository
4. Go to terraform folder: ```cd <repo>/terraform```
5. Init terraform: ```terraform init```
6. Verify the tf files and plan: ```terraform plan```
7. Deploy: ```terraform apply```

