#!/bin/bash

help() {
  echo "This script manages GCS buckets for Terraform state storage."
  echo
  echo "Usage: $0 [-create|-check|-delete|-help] [-bucket BUCKET_NAME]"
  echo "  -c, --create - create GCS bucket (if it does not exist)"
  echo "  -e, --exist  - check the existence of GCS bucket"
  echo "  -d, --delete - delete GCS bucket (if it exists)"
  echo "  -h, -?, --help   - display this help message"
  echo "Optional Arguments:"
  echo "  -b, -bucket BUCKET_NAME - set GCS Bucket Name"
}

check_bucket() {
  local EXISTING_BUCKET=$(gcloud storage ls | grep gs://$BUCKET_NAME/)

  if [ -n "$EXISTING_BUCKET" ]; then
    return 1
  else
    return 0
  fi
}

check_arguments() {
  if [ -z "$BUCKET_NAME" ]; then
    read -p "Enter the GCS Bucket Name: " BUCKET_NAME
  fi
}

if [ "$#" -eq 0 ]; then
  help
  exit 1
fi

if [ -f "variables.tf" ]; then
  BUCKET_NAME=$(awk '/backend "gcs"/,/}/' main.tf | awk '/bucket/ {gsub(/[",]+/, "", $3); print $3}')
fi

while [ "$#" -gt 0 ]; do
  case "$1" in
    -c|--create|-e|--exist|-d|--delete|-h|-?|--help)
      MODE=$1
      shift 1
      ;;
    -b|--bucket)
      BUCKET_NAME=$2
      shift 2
      ;;
    *)
      echo "Invalid argument: $1"
      echo ""
      help
      exit 1
      ;;
  esac
done

case "$MODE" in
  -c|--create)
    check_arguments
    check_bucket
    if [ $? -eq 1 ]; then
      echo "GCS backet $BUCKET_NAME already existence"
    else
      gcloud storage buckets create gs://$BUCKET_NAME
      echo "GCS bucket $BUCKET_NAME successfully created."
    fi
    exit 1
    ;;
  -e|--exist)
    check_arguments
    check_bucket
    if [ $? -eq 1 ]; then
      echo "GCS backet $BUCKET_NAME existence"
    else
      echo "GCS backet $BUCKET_NAME does NOT existence"
    fi
    exit 1
    ;;
  -d|--delete)
    check_arguments
    check_bucket
    if [ $? -eq 1 ]; then
      gcloud storage rm --recursive gs://$BUCKET_NAME/
      echo "GCS bucket $BUCKET_NAME successfully deleted."
    else
      echo "GCS basket $BUCKET_NAME does NOT exist."
    fi
    exit 1
    ;;
  -h|-?|--help)
    help
    exit 1
    ;;
esac
