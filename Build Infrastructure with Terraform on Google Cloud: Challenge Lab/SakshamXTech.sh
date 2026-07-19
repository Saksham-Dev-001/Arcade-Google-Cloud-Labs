
#!/bin/bash
set -e

# ----------------------------- Color Palette --------------------------
BLUE='\033[0;34m'
LBLUE='\033[1;34m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

BLUE_TEXT="${BLUE}${BOLD}"
GREEN_TEXT="${GREEN}${BOLD}"
YELLOW_TEXT="${YELLOW}${BOLD}"
RED_TEXT="${RED}${BOLD}"
CYAN_TEXT="${CYAN}${BOLD}"
MAGENTA_TEXT="${MAGENTA}${BOLD}"
WHITE_TEXT="${WHITE}${BOLD}"
RESET_FORMAT="${NC}"

TOTAL_PHASES=11
START_TIME=$(date +%s)

gradient_line() {
  echo -e "${BLUE}▓${LBLUE}▓${CYAN}▓${GREEN}▓${YELLOW}▓${MAGENTA}▓${RED}▓${NC}$(printf '━%.0s' {1..55})"
}

print_phase() {
  local step=$1
  local title=$2
  echo
  gradient_line
  echo -e "${YELLOW_TEXT}  [${step}/${TOTAL_PHASES}] ${title}${RESET_FORMAT}"
  gradient_line
}

success() { echo -e "${GREEN_TEXT}   ✅  $1${RESET_FORMAT}"; }
info()    { echo -e "${CYAN_TEXT}   ℹ️   $1${RESET_FORMAT}"; }
warn()    { echo -e "${RED_TEXT}   ⚠️   $1${RESET_FORMAT}"; }

elapsed_since_start() {
  local now=$(date +%s)
  echo $(( now - START_TIME ))
}
clear

# -------------------------- Welcome message -------------------------
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}           SUBSCRIBE SakshamXTech - INITIATING EXECUTION...         ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

# ----------------------------- Environment Detection -------------------------
info "Fetching Project ID..."
export PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
success "Detected Project ID: ${WHITE}$PROJECT_ID${NC}"

info "Fetching Region and Zone..."
export ZONE=$(gcloud compute instances list --limit=1 --format="value(zone.basename())")
if [ -z "$ZONE" ]; then
    export ZONE="us-west4-b"
    export REGION="us-west4"
else
    export REGION=$(echo $ZONE | awk -F'-' '{print $1"-"$2}')
fi
success "Detected Region: ${WHITE}$REGION${NC} | Zone: ${WHITE}$ZONE${NC}"

# ----------------------------- Interactive Inputs -------------------------
echo
echo -e "${MAGENTA_TEXT}   👉 Apni lab screen se details copy karke yahan paste karo:${RESET_FORMAT}"
echo
read -p "$(echo -e "${CYAN_TEXT}   🔹 Enter BUCKET_NAME (e.g., tf-bucket-xxxxxx): ${RESET_FORMAT}")" BUCKET_NAME
read -p "$(echo -e "${CYAN_TEXT}   🔹 Enter INSTANCE_NAME (e.g., tf-instance-xxxxxx): ${RESET_FORMAT}")" INSTANCE_NAME
read -p "$(echo -e "${CYAN_TEXT}   🔹 Enter VPC_NAME (e.g., tf-vpc-xxxxxx): ${RESET_FORMAT}")" VPC_NAME

if [ -z "$BUCKET_NAME" ] || [ -z "$INSTANCE_NAME" ] || [ -z "$VPC_NAME" ]; then
    warn "Koi bhi field khali nahi honi chahiye! Script ko dobara run karo."
    exit 1
fi

export BUCKET_NAME INSTANCE_NAME VPC_NAME

# ==============================================================================
print_phase "1" "📦  Installing & Verifying Terraform"
wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install -y terraform
success "Terraform installed: $(terraform --version | head -n1)"

# ==============================================================================
print_phase "2" "🗂️   Creating Directory Structure & Variables"
mkdir -p modules/instances
mkdir -p modules/storage

cat <<VARS > variables.tf
variable "region" { default = "$REGION" }
variable "zone" { default = "$ZONE" }
variable "project_id" { default = "$PROJECT_ID" }
VARS

cp variables.tf modules/instances/variables.tf
cp variables.tf modules/storage/variables.tf
touch modules/instances/outputs.tf modules/storage/outputs.tf
success "Module scaffolding created (instances + storage)"

# ==============================================================================
print_phase "3" "⚙️   Setting Up Base Configuration"
cat <<MAIN > main.tf
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}
provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}
module "instances" {
  source = "./modules/instances"
}
MAIN
success "Base main.tf written"

# ==============================================================================
print_phase "4" "📥  Importing Existing Infrastructure"
INSTANCE_1_ID=$(gcloud compute instances describe tf-instance-1 --zone=$ZONE --format="value(id)")
INSTANCE_2_ID=$(gcloud compute instances describe tf-instance-2 --zone=$ZONE --format="value(id)")

cat <<INST > modules/instances/instances.tf
resource "google_compute_instance" "tf-instance-1" {
  name         = "tf-instance-1"
  machine_type = "n1-standard-1"
  zone         = var.zone
  boot_disk {
    initialize_params { image = "debian-cloud/debian-11" }
  }
  network_interface { network = "default" }
  metadata_startup_script = "#!/bin/bash"
  allow_stopping_for_update = true
}

resource "google_compute_instance" "tf-instance-2" {
  name         = "tf-instance-2"
  machine_type = "n1-standard-1"
  zone         = var.zone
  boot_disk {
    initialize_params { image = "debian-cloud/debian-11" }
  }
  network_interface { network = "default" }
  metadata_startup_script = "#!/bin/bash"
  allow_stopping_for_update = true
}
INST

terraform init
terraform import module.instances.google_compute_instance.tf-instance-1 $INSTANCE_1_ID
terraform import module.instances.google_compute_instance.tf-instance-2 $INSTANCE_2_ID
terraform apply -auto-approve
success "Existing instances imported into state  (⏱  $(elapsed_since_start)s elapsed)"

# ==============================================================================
print_phase "5" "🪣  Creating Storage Bucket"
cat <<STRG > modules/storage/storage.tf
resource "google_storage_bucket" "backend-bucket" {
  name                        = "$BUCKET_NAME"
  location                    = "US"
  force_destroy               = true
  uniform_bucket_level_access = true
}
STRG

cat <<MAIN_STRG >> main.tf
module "storage" {
  source = "./modules/storage"
}
MAIN_STRG

terraform init
terraform apply -auto-approve
success "Bucket $BUCKET_NAME provisioned  (⏱  $(elapsed_since_start)s elapsed)"

# ==============================================================================
print_phase "6" "☁️   Configuring Remote GCS Backend"
cat <<BACKEND > main.tf
terraform {
  backend "gcs" {
    bucket = "$BUCKET_NAME"
    prefix = "terraform/state"
  }
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}
provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}
module "instances" {
  source = "./modules/instances"
}
module "storage" {
  source = "./modules/storage"
}
BACKEND

terraform init -migrate-state -force-copy
success "State migrated to gs://$BUCKET_NAME/terraform/state"

# ==============================================================================
print_phase "7" "📈  Modifying Infrastructure & Scaling Up"
cat <<INST_SCALE > modules/instances/instances.tf
resource "google_compute_instance" "tf-instance-1" {
  name         = "tf-instance-1"
  machine_type = "e2-standard-2"
  zone         = var.zone
  boot_disk {
    initialize_params { image = "debian-cloud/debian-11" }
  }
  network_interface { network = "default" }
  metadata_startup_script = "#!/bin/bash"
  allow_stopping_for_update = true
}

resource "google_compute_instance" "tf-instance-2" {
  name         = "tf-instance-2"
  machine_type = "e2-standard-2"
  zone         = var.zone
  boot_disk {
    initialize_params { image = "debian-cloud/debian-11" }
  }
  network_interface { network = "default" }
  metadata_startup_script = "#!/bin/bash"
  allow_stopping_for_update = true
}

resource "google_compute_instance" "$INSTANCE_NAME" {
  name         = "$INSTANCE_NAME"
  machine_type = "e2-standard-2"
  zone         = var.zone
  boot_disk {
    initialize_params { image = "debian-cloud/debian-11" }
  }
  network_interface { network = "default" }
  metadata_startup_script = "#!/bin/bash"
  allow_stopping_for_update = true
}
INST_SCALE

terraform apply -auto-approve
success "Scaled tf-instance-1/2 to e2-standard-2 and added $INSTANCE_NAME  (⏱  $(elapsed_since_start)s elapsed)"

# ==============================================================================
print_phase "8" "🗑️   Destroying the Third Instance"
cat <<INST_DESTROY > modules/instances/instances.tf
resource "google_compute_instance" "tf-instance-1" {
  name         = "tf-instance-1"
  machine_type = "e2-standard-2"
  zone         = var.zone
  boot_disk {
    initialize_params { image = "debian-cloud/debian-11" }
  }
  network_interface { network = "default" }
  metadata_startup_script = "#!/bin/bash"
  allow_stopping_for_update = true
}

resource "google_compute_instance" "tf-instance-2" {
  name         = "tf-instance-2"
  machine_type = "e2-standard-2"
  zone         = var.zone
  boot_disk {
    initialize_params { image = "debian-cloud/debian-11" }
  }
  network_interface { network = "default" }
  metadata_startup_script = "#!/bin/bash"
  allow_stopping_for_update = true
}
INST_DESTROY

terraform apply -auto-approve
success "$INSTANCE_NAME destroyed, back to tf-instance-1/2 only  (⏱  $(elapsed_since_start)s elapsed)"

# ==============================================================================
print_phase "9" "🌐  Deploying Registry VPC Network"
cat <<MAIN_VPC >> main.tf
module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "~> 10.0"
  project_id   = var.project_id
  network_name = "$VPC_NAME"
  routing_mode = "GLOBAL"
  subnets = [
    {
      subnet_name   = "subnet-01"
      subnet_ip     = "10.10.10.0/24"
      subnet_region = var.region
    },
    {
      subnet_name   = "subnet-02"
      subnet_ip     = "10.10.20.0/24"
      subnet_region = var.region
    }
  ]
}
MAIN_VPC

terraform init
terraform apply -auto-approve
success "VPC $VPC_NAME with subnet-01/02 deployed  (⏱  $(elapsed_since_start)s elapsed)"

# ==============================================================================
print_phase "10" "🔀  Routing Instances to New VPC Subnets"
cat <<INST_VPC > modules/instances/instances.tf
resource "google_compute_instance" "tf-instance-1" {
  name         = "tf-instance-1"
  machine_type = "e2-standard-2"
  zone         = var.zone
  boot_disk {
    initialize_params { image = "debian-cloud/debian-11" }
  }
  network_interface {
    network    = "$VPC_NAME"
    subnetwork = "subnet-01"
  }
  metadata_startup_script = "#!/bin/bash"
  allow_stopping_for_update = true
}

resource "google_compute_instance" "tf-instance-2" {
  name         = "tf-instance-2"
  machine_type = "e2-standard-2"
  zone         = var.zone
  boot_disk {
    initialize_params { image = "debian-cloud/debian-11" }
  }
  network_interface {
    network    = "$VPC_NAME"
    subnetwork = "subnet-02"
  }
  metadata_startup_script = "#!/bin/bash"
  allow_stopping_for_update = true
}
INST_VPC

terraform apply -auto-approve
success "Instances rewired onto $VPC_NAME subnets  (⏱  $(elapsed_since_start)s elapsed)"

# ==============================================================================
print_phase "11" "🔥  Configuring Firewall Rule"
cat <<MAIN_FW >> main.tf
resource "google_compute_firewall" "tf-firewall" {
  name    = "tf-firewall"
  network = "$VPC_NAME"
  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
  source_ranges = ["0.0.0.0/0"]
}
MAIN_FW

terraform apply -auto-approve
success "Firewall rule tf-firewall allowing tcp:80 created  (⏱  $(elapsed_since_start)s elapsed)"

# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@sakshamxtech${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
echo