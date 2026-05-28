#!/bin/bash

# Enhanced Color Definitions
BLACK='\033[0;30m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'

# Bold Colors
BOLD_BLACK='\033[1;30m'
BOLD_RED='\033[1;31m'
BOLD_GREEN='\033[1;32m'
BOLD_YELLOW='\033[1;33m'
BOLD_BLUE='\033[1;34m'
BOLD_MAGENTA='\033[1;35m'
BOLD_CYAN='\033[1;36m'
BOLD_WHITE='\033[1;37m'

# Background Colors
BG_BLACK='\033[40m'
BG_RED='\033[41m'
BG_GREEN='\033[42m'
BG_YELLOW='\033[43m'
BG_BLUE='\033[44m'
BG_MAGENTA='\033[45m'
BG_CYAN='\033[46m'
BG_WHITE='\033[47m'

# Special Formats
UNDERLINE='\033[4m'
BLINK='\033[5m'
REVERSE='\033[7m'
HIDDEN='\033[8m'

RESET='\033[0m'

#----------------------------------------------------start--------------------------------------------------#

# Header
echo "${CYAN_TEXT}${BOLD_CYAN}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_BLUE}      SUBSCRIBE SakshamXTech- INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_CYAN}==================================================================${RESET_FORMAT}"
echo

#!/bin/bash

read -p "Enter LANGUAGE (e.g. en): " LANGUAGE
read -p "Enter LOCAL (e.g. en_US): " LOCAL
read -p "Enter BIGQUERY_ROLE: " BIGQUERY_ROLE
read -p "Enter CLOUD_STORAGE_ROLE: " CLOUD_STORAGE_ROLE

echo "Creating Service Account..."

gcloud iam service-accounts create sample-sa

echo "Assigning IAM Roles..."

gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
--member=serviceAccount:sample-sa@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com \
--role=$BIGQUERY_ROLE

gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
--member=serviceAccount:sample-sa@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com \
--role=$CLOUD_STORAGE_ROLE

gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
--member=serviceAccount:sample-sa@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com \
--role=roles/serviceusage.serviceUsageConsumer

echo "Waiting for IAM propagation..."
sleep 120

echo "Creating Service Account Key..."

gcloud iam service-accounts keys create sample-sa-key.json \
--iam-account=sample-sa@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com

export GOOGLE_APPLICATION_CREDENTIALS=${PWD}/sample-sa-key.json

echo "Downloading Image Analysis Script..."

wget -O analyze-images-v2.py \
https://raw.githubusercontent.com/guys-in-the-cloud/cloud-skill-boosts/main/Challenge-labs/Integrate%20with%20Machine%20Learning%20APIs%3A%20Challenge%20Lab/analyze-images-v2.py

echo "Updating Locale..."

sed -i "s/'en'/'${LOCAL}'/g" analyze-images-v2.py

echo "Running Image Analysis..."

python3 analyze-images-v2.py
python3 analyze-images-v2.py $DEVSHELL_PROJECT_ID $DEVSHELL_PROJECT_ID

echo "Fetching BigQuery Results..."

bq query --use_legacy_sql=false \
"SELECT locale, COUNT(locale) as lcount 
FROM image_classification_dataset.image_text_detail 
GROUP BY locale 
ORDER BY lcount DESC"


# Completion Message
echo "${CYAN_TEXT}${BOLD_CYAN}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_YELLOW}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_CYAN}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_RED}${UNDERLINE_TEXT}https://www.youtube.com/@sakshamxtech${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_GREEN}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
echo

#-----------------------------------------------------end----------------------------------------------------------#