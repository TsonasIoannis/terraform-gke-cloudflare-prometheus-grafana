# Monitoring GKE with Terraform, Prometheus, Grafana, Cloudflare

This repository contains Terraform scripts for provisioning infrastructure on Google Cloud Platform (GCP) and Cloudflare. These scripts are designed to automate the setup and management of various GCP resources.
The end goal is a fully functional monitoring and observability platform that can be scaled and extended to meet any needs.

## GCP Bootstrap

1. Creating a Google Cloud Platform Project via CLI

### Prerequisites

Before creating a GCP project using the CLI, ensure you have the following:

- **GCP Account**: Access to a Google Cloud Platform account.
- **Google Cloud SDK**: Install the [Google Cloud SDK](https://cloud.google.com/sdk) on your local machine.
- **Authentication**: Authenticate the CLI with your GCP account using `gcloud auth login`.

### Step 1: Initialize the SDK

Open your terminal or command prompt and ensure the Google Cloud SDK is properly initialized:

```bash
gcloud init
```

Follow the prompts to log in and configure the SDK to use your GCP account.

### Step 2: Create a New GCP Project

Use the following command to create a new GCP project:

```bash
gcloud projects create PROJECT_ID --name="PROJECT_NAME"
```

Replace `PROJECT_ID` with your desired project ID and `PROJECT_NAME` with a descriptive name for the project.

### Step 3: Set the Current Project

After creating the project, set it as the current active project for further operations:

```bash
gcloud config set project PROJECT_ID
```

Replace `PROJECT_ID` with the ID of the project you just created.

### Step 4: Enable Billing (Optional)

For the newly created project, ensure billing is enabled:

```bash
gcloud alpha billing projects link PROJECT_ID --billing-account=BILLING_ACCOUNT_ID
```

Replace `PROJECT_ID` with the ID of the created project and `BILLING_ACCOUNT_ID` with your billing account ID.

2. Creating a GCP Service Account with Owner Permissions via CLI

### Step 1: Create a Service Account

Use the following command to create a service account:

```bash
gcloud iam service-accounts create SERVICE_ACCOUNT_NAME --description="DESCRIPTION" --display-name="DISPLAY_NAME"
```

Replace `SERVICE_ACCOUNT_NAME` with the name you want to give the service account, `DESCRIPTION` with a brief description, and `DISPLAY_NAME` with a human-readable name for the service account.

### Step 2: Assign Owner Role to the Service Account

Grant the owner role to the service account for the project:

```bash
gcloud projects add-iam-policy-binding PROJECT_ID --member="serviceAccount:SERVICE_ACCOUNT_EMAIL" --role="roles/owner"
```

Replace `PROJECT_ID` with the ID of the GCP project where the service account was created and `SERVICE_ACCOUNT_EMAIL` with the email address of the service account you created in Step 1 (`SERVICE_ACCOUNT_NAME@PROJECT_ID.iam.gserviceaccount.com`).

### Step 3: Generate and Download Key

Generate a key for the service account and save it to a file (e.g., keyfile.json):

```bash
gcloud iam service-accounts keys create keyfile.json --iam-account=SERVICE_ACCOUNT_EMAIL
```

Replace `keyfile.json` with the desired filename and `SERVICE_ACCOUNT_EMAIL` with the email address of the service account.

### Additional Information

- **Permissions**: Ensure your GCP account has sufficient permissions to create projects. Users must have the `resourcemanager.projects.create` permission on the organization or folder where the project will be created.
- **Project ID**: The project ID must be unique within GCP, and it's immutable after creation.
- **Permissions**: Ensure your account has sufficient permissions (`roles/iam.serviceAccountAdmin` or equivalent) to create service accounts and assign roles.
- **Service Account Roles**: Instead of assigning the owner role, consider assigning specific roles based on the required permissions for security reasons.

3. Setting GitHub Secrets for Google Cloud Credentials

To securely manage sensitive information like `GOOGLE_PROJECT` and `GOOGLE_CREDENTIALS` when using GitHub Actions or workflows, GitHub provides a feature called secrets. These secrets allow you to store sensitive data encrypted and then use them within your workflows.

### Step 1: Get the Google Cloud Service Account Key

Before setting up GitHub secrets, ensure you have the Google Cloud Service Account key JSON file handy. This file contains the credentials required to authenticate with Google Cloud.

### Step 2: Add `GOOGLE_PROJECT` Secret

1. **Go to Your Repository**: Open your GitHub repository in your browser.
2. **Navigate to Settings**: Click on the "Settings" tab.
3. **Access Secrets**: Choose "Secrets" from the left sidebar.
4. **Add New Secret**: Click on "New repository secret".
5. **Set Name and Value**:
   - For `GOOGLE_PROJECT`:
     - Name: `GOOGLE_PROJECT`
     - Value: Enter your Google Cloud Platform Project ID.

### Step 3: Add `GOOGLE_CREDENTIALS` Secret

1. **Go to Your Repository Settings**.
2. **Access Secrets**.
3. **Add New Secret**.
4. **Set Name and Value**:
   - For `GOOGLE_CREDENTIALS`:
     - Name: `GOOGLE_CREDENTIALS`
     - Value: Paste the entire content of the Google Cloud Service Account key JSON file into the value field.

### Step 4: Accessing Secrets in GitHub Workflows

In your GitHub Actions or workflows, you can access these secrets using the following syntax:

```yaml
jobs:
  example_job:
    runs-on: ubuntu-latest
    env:
      GOOGLE_PROJECT: ${{ secrets.GOOGLE_PROJECT }}
      GOOGLE_CREDENTIALS: ${{ secrets.GOOGLE_CREDENTIALS }}
    steps:
      # Use the secrets in your workflow steps as needed
```

Ensure you're referencing these secrets correctly within your workflows or actions to use the sensitive information securely.

### Note

- **Security**: Treat secrets with care. Avoid exposing them in logs or outputs.
- **Access Control**: Limit access to repository secrets to authorized personnel.

## Getting Started

To use these Terraform scripts locally, follow these steps:

1. **Prerequisites**: Make sure you have [Terraform](https://www.terraform.io/downloads.html) installed locally.

2. **Authentication**: Set up authentication to GCP by creating a service account, downloading the JSON key file, and setting the `GOOGLE_APPLICATION_CREDENTIALS` environment variable.

3. **Configuration**: Customize the `terraform.tfvars` file to specify the desired configuration, such as project ID, region, or resource-specific settings.

4. **Initialize**: Run `terraform init` in the terminal to initialize the working directory containing Terraform configuration files.

5. **Planning**: Use `terraform plan` to preview the changes that Terraform will make to the infrastructure.

6. **Apply Changes**: Execute `terraform apply` to create or modify the GCP resources as defined in the configuration files.

Alternatively you can run the workflow in a GitHub Actions with this [workflow](/.github/workflows/terraform.yml)

## Folder Structure

- **`main.tf`**: Contains the main Terraform provider configuration
- **`provider_group.tf`**: defining the infrastructure resources to be provisioned.
- **`variables.tf`**: Defines the input variables used in the Terraform configuration.
- **`terraform.tfvars`**: This file is used to set variable values specific to your environment. (Note: Ensure sensitive information like keys or secrets is not committed to version control.)
- **`outputs.tf`**: Defines the output values that will be displayed after running `terraform apply`.

## Additional Information

- **Documentation**: For detailed information on using Terraform with GCP, refer to the [Terraform Google Provider Documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs).
- **Issues and Contributions**: If you encounter any issues or would like to contribute, please feel free to open an issue or pull request in this repository.

## License

This repository is licensed under the [MIT License](LICENSE).
