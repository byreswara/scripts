# This script can be used to set up new storage accounts for blob storage in azure. Be sure to run "az login" before running the script.

param (
    $location = "centralus", #Default centralus
    $deployer = "Mathew Ashley",
    $project = "terraform"
)

$time = [Xml.XmlConvert]::ToString((Get-Date), [Xml.XmlDateTimeSerializationMode]::Utc)

#Define tags for created resources in azure


###############################
#         Main Script         #
###############################

# array containing three environment variables to be used in the script, one for qa, one for uat, and one for prod.
$envs = @("qa", "uat", "prod")

# Loop through each environment variable and create a storage account for each
foreach ($env in $envs) {
    $storageaccount_name = "sttctf$env`cus001"
    $storageaccount_rg = "rg-terraform-$env"
    
    # switch to the correct subscription
    switch ($env) {
        "qa" {
            $SubscriptionID = "9b28bd6c-83d4-4721-b1e9-cec8810ab5f9"
        }
        "uat" {
            $SubscriptionID = "50bc17fa-ab53-4515-8150-3338c2e9840f"
        }
        "prod" {
            $SubscriptionID = "5429f7aa-0e72-4bdb-a036-328ffc0674fa"
        }
    }

    $tags = @(
        "deployer=$deployer",
        "environment=$env",
        "location=$location",
        "project=$project",
        "CreationDate=$time"
        "Description=Storage Account for Terraform State Data"
    )

    # Set account to specified subscription
    az account set -s $SubscriptionID

    # Check for existing resource group or create new
    $rgCheck = az group exists --name $storageaccount_rg

    if ($rgCheck -ne $true) {
        Write-Host "Creating Resource Group" -ForegroundColor green    
        az group create `
            --name $storageaccount_rg `
            --location $location `
            --tags $tags
        Start-Sleep 10
        $rgCheck = az group exists --name $storageaccount_rg
    }
    else {
        Write-Host "The resource group: `"$storageaccount_rg`" already exists" -ForegroundColor yellow
    }

    Write-Host "=============================================================="
    Write-Host "Checking for existing storage account: `"$storageaccount_name`"" -ForegroundColor yellow
    # Check if storage account name is available and create new if so
    $stCheck = az storage account check-name --name $storageaccount_name
    $stNameCheck = az storage account check-name --name $storageaccount_name --query nameAvailable
    if ($stNameCheck -eq 'true') {
        Write-Host "Creating Storage Account" -ForegroundColor green
        az storage account create `
            --name $storageaccount_name `
            --resource-group $storageaccount_rg `
            --kind StorageV2 `
            --sku Standard_LRS `
            --https-only true `
            --allow-blob-public-access false `
            --min-tls-version TLS1_2 `
            --tags $tags
    }
    else {
        $stCheck
    }
}