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

### Notes

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

## Detailed Guide

The following section includes various configuration options with explanation of their use.

### GKE network

Every GKE cluster needs a VPC network to manage its internal network which includes private IP allocation for its pods and services.

For our private GKE the following resources are used in Terraform:

```terraform
resource "google_compute_network" "monitoring-vpc" {
  project                 = google_project.monitoring.project_id
  name                    = "monitoring-vpc"
  routing_mode            = "GLOBAL"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "monitoring-subnet" {
  project                  = google_project.monitoring.project_id
  name                     = "monitoring-subnet"
  region                   = "europe-west2"
  network                  = google_compute_network.monitoring-vpc.id
  ip_cidr_range            = "10.0.1.0/24"
  private_ip_google_access = true

  secondary_ip_range {
    range_name    = "monitoring-services"
    ip_cidr_range = "10.10.0.0/24"
  }
  secondary_ip_range {
    range_name    = "monitoring-pods"
    ip_cidr_range = "10.20.0.0/22"
  }
}
```

Some notes include the `auto_create_subnetworks = false` because we want to control all subnetworks from our configuration. In the subnetwrok resource we specify to IP ranges to separate our pods and services. Need to verify that the IP ranges defined can support all the pods and services in case of scaling.

The next lump of network configuration regards the ability to pull images outside of Google Container Services. If you are using only GCR for your deployments this can be omitted.

```terraform
resource "google_compute_router" "monitoring-router" {
  project = google_project.monitoring.project_id
  name    = "monitoring-router"
  network = google_compute_network.monitoring-vpc.id
  region  = "europe-west2"
}

resource "google_compute_router_nat" "monitoring-nat" {
  project                            = google_project.monitoring.project_id
  region                             = "europe-west2"
  name                               = "monitoring-nat"
  router                             = google_compute_router.monitoring-router.name
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  min_ports_per_vm                   = "64"
  udp_idle_timeout_sec               = "30"
  icmp_idle_timeout_sec              = "30"
  tcp_established_idle_timeout_sec   = "1200"
  tcp_transitory_idle_timeout_sec    = "30"
  tcp_time_wait_timeout_sec          = "120"
  enable_dynamic_port_allocation     = false
}
```

### GKE private cluster

For the actual cluster we use the following resource:

```terraform

resource "google_container_cluster" "monitoring" {
  project            = google_project.monitoring.project_id
  name               = "monitoring"
  location           = "europe-west2-a"
  resource_labels    = {}
  min_master_version = "1.26.2-gke.1000"
  remove_default_node_pool = true
  initial_node_count       = 1
  network    = google_compute_network.monitoring-vpc.name
  subnetwork = google_compute_subnetwork.monitoring-subnet.name
  ip_allocation_policy {
    cluster_secondary_range_name  = "monitoring-pods"
    services_secondary_range_name = "monitoring-services"
  }
  workload_identity_config {
    workload_pool = "${google_project.monitoring.project_id}.svc.id.goog"
  }
  master_authorized_networks_config {
  }
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = true
    # Not sure how this value is set
    # Documentation: specifies an internal IP address range for the control plane
    master_ipv4_cidr_block = "10.1.0.0/28"
  }
  node_config {
    service_account = google_service_account.monitoring.email
  }
  lifecycle {
    ignore_changes = [node_config]
  }
}
```

One important segment is the `remove_default_node_pool = true` and `initial_node_count = 1` which allows us to manage all the nodes from our configuration.
In order to make the cluster private, which means that nodes only have internal IP addresses, which means that nodes and Pods are isolated from the internet by default we need the following sections `master_authorized_networks_config` as empty and the `private_cluster_config` to configure the nodes with private endpoints to the VPC.

The actual node pool is managed from this resource:

```terraform
resource "google_container_node_pool" "monitoring-nodes" {
  name       = google_container_cluster.monitoring.name
  location   = "europe-west2-a"
  cluster    = google_container_cluster.monitoring.name
  node_count = 1

  node_config {
    resource_labels = {}
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    labels = {
      env = google_project.monitoring.project_id
    }

    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    preemptible  = false
    machine_type = "e2-medium"
  }
}
```

The `machine_type` section controls the underlying VM size which correlates to the cost of the resource.

We also provision a helpers service account to limit the GKE IAM controls:

```terraform
resource "google_service_account" "monitoring" {
  project      = google_project.monitoring.project_id
  account_id   = "monitoring"
  display_name = "Monitoring Service Account"
}

locals {
  monitoring_service_account_roles = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/stackdriver.resourceMetadata.writer",
    "roles/storage.objectViewer",
    "roles/artifactregistry.reader"
  ]
}

resource "google_project_iam_member" "monitoring_service_account-roles" {
  for_each = toset(local.monitoring_service_account_roles)

  project = google_project.monitoring.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.monitoring.email}"
}
```

### GKE Fleet

The most interesting part about the private GKE how can we manage future deployments if the cluster is not connected to the internet?

A solution is to register the cluster to an Anthos fleet. Fleets are generally used for multi cluster management and offer a wide variety of services but we are particularly interested in the Connect Gateway authentication method.

The resource for registering the cluster in the fleet is this one:

```terraform
resource "google_gke_hub_membership" "monitoring" {
  project       = google_project.monitoring.project_id
  membership_id = "monitoring"

  endpoint {
    gke_cluster {
      resource_link = "//container.googleapis.com/${google_container_cluster.monitoring.id}"
    }
  }
  authority {
    issuer = "https://container.googleapis.com/v1/${google_container_cluster.monitoring.id}"
  }
}
```

We will see how that affects the authentication for the deployment providers i.e. the Kubernetes and Helm providers.

### Kubernetes and Helm providers

The next step is to deploy the Prometheus and Grafana servers and services. This can be achieved by utilising the Terraform Kubernetes and Helm providers.
These providers need to access the cluster in order to perform the deploy process. Since the cluster is private this is not possible via the conventional authentication methods.
Anthos Connect Gatewat to the rescue! Since we have a cluster gateway we can use the `gke-gcloud-auth-plugin` which uses the Terraform service account token to authenticate to the cluster without compromising security.
The provider also needs the hub membership endpoint as the `host` argument.
Finally the alias argument is also used in case you want to use the providers with other clusters.
The overall configuration for the providers is this section:

```terraform
locals {
  connect_gateway = "https://connectgateway.googleapis.com/v1/projects/${google_project.monitoring.number}/locations/global/gkeMemberships/${google_container_cluster.monitoring.name}"
}

provider "kubernetes" {
  host  = local.connect_gateway
  token = data.google_client_config.default.access_token
  alias = "monitoring"
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "gke-gcloud-auth-plugin"
  }
}

provider "helm" {
  alias = "monitoring"
  kubernetes {
    host  = local.connect_gateway
    token = data.google_client_config.default.access_token
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "gke-gcloud-auth-plugin"
    }
  }
}
```

### Prometheus and Grafana deployments

For the actual deployments we will use Helm charts to maintain a versioned release.
In the `templates` directory we have included the entire values options in order to manage all the options available.
However when bumping to new versions the temlates must be updated as well so the best would be to only include some values in through the Helm release through the set as demonstrated in the resources.

Please note that this is a vanilla Prometheus server in order to showcase the base scenario and walk through all the possible configurable options.
However, I also include the Prometheus Operator Custom Resource Definitions as a deployment which are required by some exporters.

Alternatively, there are various Helm [charts](https://github.com/prometheus-community/helm-charts) supported by the community for extended functionality.

## Additional Information

- **Documentation**: For detailed information on using Terraform with GCP, refer to the [Terraform Google Provider Documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs).
- **Issues and Contributions**: If you encounter any issues or would like to contribute, please feel free to open an issue or pull request in this repository.

## License

This repository is licensed under the [MIT License](LICENSE).
