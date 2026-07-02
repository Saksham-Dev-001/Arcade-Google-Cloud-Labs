#!/bin/bash

# Color definitions
BLACK=`tput setaf 0`
RED=`tput setaf 1`
GREEN=`tput setaf 2`
YELLOW=`tput setaf 3`
BLUE=`tput setaf 4`
MAGENTA=`tput setaf 5`
CYAN=`tput setaf 6`
WHITE=`tput setaf 7`

BG_BLACK=`tput setab 0`
BG_RED=`tput setab 1`
BG_GREEN=`tput setab 2`
BG_YELLOW=`tput setab 3`
BG_BLUE=`tput setab 4`
BG_MAGENTA=`tput setab 5`
BG_CYAN=`tput setab 6`
BG_WHITE=`tput setab 7`

BOLD=`tput bold`
RESET=`tput sgr0`

clear

# Welcome message
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}      SUBSCRIBE SakshamXTech- INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

export PROJECT_ID=$(gcloud info --format='value(config.project)')

# Task 1: Enable Security Command Center
echo "${BLUE}${BOLD}Task 1: Enabling Security Command Center service...${RESET}"
gcloud services enable securitycenter.googleapis.com &
spinner

# Wait until the service is enabled
echo "${MAGENTA}${BOLD}Waiting for service to be fully enabled...${RESET}"
while true; do
  SERVICE_STATUS=$(gcloud services list --enabled | grep "securitycenter.googleapis.com")
  if [ -n "$SERVICE_STATUS" ]; then
    break
  fi
  sleep 2
done

echo "${GREEN}${BOLD}✅ Security Command Center service enabled${RESET}"
echo ""

# Task 2: Create mute configuration
echo "${BLUE}${BOLD}Task 2: Creating mute configuration for VPC Flow Logs...${RESET}"
gcloud scc muteconfigs create mute-flowlogs-findings \
  --project=$DEVSHELL_PROJECT_ID \
  --description="Mute rule for VPC Flow Logs" \
  --filter="category=\"FLOW_LOGS_DISABLED\"" &
spinner

echo "${GREEN}${BOLD}✅ Task 3.1 Completed - Mute configuration created${RESET}"
echo ""

# Task 3: Create network
echo "${BLUE}${BOLD}Task 3: Creating VPC network...${RESET}"
gcloud compute networks create scc-lab-net --subnet-mode=auto &
spinner

echo "${GREEN}${BOLD}✅ Task 3.2 Completed - Network created${RESET}"
echo ""

# Task 4: Update firewall rules
echo "${BLUE}${BOLD}Task 4: Updating firewall rules for IAP...${RESET}"
gcloud compute firewall-rules update default-allow-rdp --source-ranges=35.235.240.0/20 &
spinner

gcloud compute firewall-rules update default-allow-ssh --source-ranges=35.235.240.0/20 &
spinner

echo "${GREEN}${BOLD}✅ Task 3.3 Completed - Firewall rules updated${RESET}"
echo ""

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@sakshamxtech${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"