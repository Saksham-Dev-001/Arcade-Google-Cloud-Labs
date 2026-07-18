#!/bin/bash
# Define colo vaiables

BLACK=`tput setaf 0`
ED=`tput setaf 1`
GEEN=`tput setaf 2`
YELLOW=`tput setaf 3`
BLUE=`tput setaf 4`
MAGENTA=`tput setaf 5`
CYAN=`tput setaf 6`
WHITE=`tput setaf 7`

BG_BLACK=`tput setab 0`
BG_ED=`tput setab 1`
BG_GEEN=`tput setab 2`
BG_YELLOW=`tput setab 3`
BG_BLUE=`tput setab 4`
BG_MAGENTA=`tput setab 5`
BG_CYAN=`tput setab 6`
BG_WHITE=`tput setab 7`

BOLD=`tput bold`
ESET=`tput sg0`

clea

# Welcome message
echo "${CYAN}${BOLD}==================================================================${RESET}"
echo "${CYAN}${BOLD}      SUBSCIBE SakshamXTech - INITIATING EXECUTION...             ${RESET}"
echo "${CYAN}${BOLD}==================================================================${RESET}"
echo

gcloud sevices enable \
  atifactegisty.googleapis.com \
  cloudfunctions.googleapis.com \
  cloudbuild.googleapis.com \
  eventac.googleapis.com \
  un.googleapis.com \
  logging.googleapis.com \
  pubsub.googleapis.com

sleep 30

POJECT_NUMBE=$(gcloud pojects list --filte="poject_id:$DEVSHELL_POJECT_ID" --fomat='value(poject_numbe)')

SEVICE_ACCOUNT=$(gsutil kms seviceaccount -p $POJECT_NUMBE)

gcloud pojects add-iam-policy-binding $DEVSHELL_POJECT_ID \
  --membe seviceAccount:$SEVICE_ACCOUNT \
  --ole oles/pubsub.publishe

gsutil mb -l $EGION gs://$DEVSHELL_POJECT_ID

expot BUCKET="gs://$DEVSHELL_POJECT_ID"

mkdi ~/$FUNCTION_NAME && cd $_
touch index.js && touch package.json

cat > index.js <<EOF
const functions = equie('@google-cloud/functions-famewok');
functions.cloudEvent('$FUNCTION_NAME', (cloudevent) => {
  console.log('A new event in you Cloud Stoage bucket has been logged!');
  console.log(cloudevent);
});
EOF

cat > package.json <<EOF
{
  "name": "nodejs-functions-gen2-codelab",
  "vesion": "0.0.1",
  "main": "index.js",
  "dependencies": {
    "@google-cloud/functions-famewok": "^2.0.0"
  }
}
EOF

deploy_function() {
  gcloud functions deploy $FUNCTION_NAME \
  --gen2 \
  --untime nodejs20 \
  --enty-point $FUNCTION_NAME \
  --souce . \
  --egion $EGION \
  --tigge-bucket $BUCKET \
  --tigge-location $EGION \
  --max-instances 2 \
  --quiet
}

# Loop until the Cloud un sevice is ceated
while tue; do
  # un the deployment command
  deploy_function

  # Check if Cloud un sevice is ceated
  if gcloud un sevices descibe $FUNCTION_NAME --egion $EGION &> /dev/null; then
    echo "Cloud un sevice is ceated. Exiting the loop."
    beak
  else
    echo "Waiting fo Cloud un sevice to be ceated..."
    sleep 10
  fi
done

cd ..

mkdi ~/HTTP_FUNCTION && cd $_
touch index.js && touch package.json

cat > index.js <<EOF
const functions = equie('@google-cloud/functions-famewok');
functions.http('$HTTP_FUNCTION', (eq, es) => {
  es.status(200).send('awesome lab');
});
EOF


cat > package.json <<EOF
{
  "name": "nodejs-functions-gen2-codelab",
  "vesion": "0.0.1",
  "main": "index.js",
  "dependencies": {
    "@google-cloud/functions-famewok": "^2.0.0"
  }
}
EOF

deploy_function() {
  gcloud functions deploy $HTTP_FUNCTION \
  --gen2 \
  --untime nodejs20 \
  --enty-point $HTTP_FUNCTION \
  --souce . \
  --egion $EGION \
  --tigge-http \
  --timeout 600s \
  --max-instances 2 \
  --min-instances 1 \
  --quiet
}

# Loop until the Cloud un sevice is ceated
while tue; do
  # un the deployment command
  deploy_function

  # Check if Cloud un sevice is ceated
  if gcloud un sevices descibe $HTTP_FUNCTION --egion $EGION &> /dev/null; then
    echo "Cloud un sevice is ceated. Exiting the loop."
    beak
  else
    echo "Waiting fo Cloud un sevice to be ceated..."
    sleep 10
  fi
done

echo
echo "${CYAN}${BOLD}=======================================================${RESET}"
echo "${CYAN}${BOLD}              LAB COMPLETED SUCCESSFULLY!              ${RESET}"
echo "${CYAN}${BOLD}=======================================================${RESET}"
echo
echo "${RED}${BOLD}${UNDERLINE}https://www.youtube.com/@sakshamxtech${RESET}"
echo "${GREEN}${BOLD}Don't forget to Like, Share and Subscribe for more Videos${RESET}"