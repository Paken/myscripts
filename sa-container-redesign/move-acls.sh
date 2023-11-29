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
blob_containers=("curated", "enriched-harmonized", "enrich-unharmonized", "raw")

# Get Storage Account Key
account_key=$(az storage account keys list --resource-group $resource_group_name --account-name $storage_account_name --output json | jq -r '.[0].value')

# 1. Get ACLs of the list of blob containers
for container in "${blob_containers[@]}"; do
    acl=$(az storage container show-permission --account-name $storage_account_name --account-key $account_key --name $container --auth-mode key --output json)
    
    # 2. Make directories with the same name inside the existing blob container
    az storage blob upload --account-name $storage_account_name --account-key $account_key --container-name $existing_container --name $container/acl.json --type block --content-type "application/json" --content-encoding "utf-8" --content $acl
    
    echo "Directory '$container' created with ACL in '$existing_container'."
done

echo "Script executed successfully."