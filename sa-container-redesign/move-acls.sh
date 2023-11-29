#!/bin/bash

# Check if the required number of arguments is provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <storage_account_name> <resource_group_name>"
    exit 1
fi

# Azure Storage Account Name
storage_account_name=$1

# Resource Group Name
resource_group_name=$2

# Existing Blob Container Name
existing_container="deltalake"

# List of Blob Containers
blob_containers=("curated" "enriched-harmonized" "enriched-unharmonized" "raw")

# Get Storage Account Key
account_key=$(az storage account keys list --resource-group $resource_group_name --account-name $storage_account_name --output json | jq -r '.[0].value')

# 1. Get ACLs of the list of blob containers
for container in "${blob_containers[@]}"; do
    acl=$(az storage fs access show --account-name $storage_account_name --path / --file-system $container --account-key $account_key --output json | grep acl | awk '{print $2}' | sed -e "s/\"//g" | sed -e "s/\,$//g")

    # 2. Make directories with the same name inside the existing blob container
    az storage fs directory create --account-name $storage_account_name --account-key $account_key --file-system $existing_container --name $container
    az storage fs access update-recursive --acl $acl --path /$container --file-system $existing_container --account-name $storage_account_name --account-key $account_key

    echo "Directory '$container' created with ACL in '$existing_container'."
done

echo "Script executed successfully."