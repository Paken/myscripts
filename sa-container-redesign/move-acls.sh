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

# Loop through the list of containers
for container in "${blob_containers[@]}"; do
    
    # Does the container exist?
    exists=$(az storage fs exists --name $container --account-name $storage_account_name --account-key $account_key | grep exists | awk '{print $2}')

    # Performing the operations if it does exist
    if [ $exists = "true" ];
    then
        # Get ACLs, owners and groups of the list of blob containers
        acl=$(az storage fs access show --account-name $storage_account_name --account-key $account_key --file-system $container --path / --output json | grep acl | awk '{print $2}' | sed -e "s/\"//g" | sed -e "s/\,$//g")
        owner=$(az storage fs access show --account-name $storage_account_name --account-key $account_key --file-system $container --path / --output json | grep owner | awk '{print $2}' | sed -e "s/\"//g" | sed -e "s/\,$//g")
        group=$(az storage fs access show --account-name $storage_account_name --account-key $account_key --file-system $container --path / --output json | grep \"group\" | awk '{print $2}' | sed -e "s/\"//g" | sed -e "s/\,$//g")

        # Make directories with the same name inside the existing blob container
        az storage fs directory create --account-name $storage_account_name --account-key $account_key --file-system $existing_container --name $container
 
        # Set ACLs in the new directories (including owner and group)
        az storage fs access set --account-name $storage_account_name --account-key $account_key --acl $acl --file-system $existing_container --path /$container --owner $owner --group $group
        az storage fs access update-recursive --account-name $storage_account_name --account-key $account_key --acl $acl --file-system $existing_container --path /$container

        echo "Directory '$container' created with ACL in '$existing_container'."
    else
        echo "WARNING: The container '$container' doesn't exist."
    fi
done