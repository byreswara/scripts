# Requires azure cli and contributor permissions for the storage account
param (
    Parameter help description
    [Parameter(Mandetory = $true)]
    [String]$serviceName, # $(ServiceName)
    [Parameter(Mandetory = $true)]
    [string]$EnvironmentName, # $(EnvironmentName)
    [Parameter(Mandetory = $true)]
    [string]$SubscriptionID, # $(SubscriptionID)
    [Parameter(Mandetory = $true)]
    [string]$container_name, # "ai-$ServiceName-$EnvironmentName-tf"
    [Parameter(Mandetory = $true)]
    [string]$storageaccount_name, # "stterraform$EnvironmentName`cus001"
    [Parameter(Mandetory = $true)]
    [string]$storageaccount_key # $(storageaccount_key) #This should be kept secret in pipelines
)

###############################
# Variables for local testing #
###############################

# $SubscriptionID = ""
# $container_name = "" #<serviceName>_<resource>_tfstate_<env> ex: claim_ai_tfstate_qa
# $storageaccount_name = "" #st<application><env><short_location><###> ex: stterraformqacus001
# $storageaccount_key = ""

###############################
#         Main Script         #
###############################

# Set account to specified subscription
az account set -s $SubscriptionID
$containerCheck = $null
try {
    $containerCheck = az storage container exists `
        --account-name $storageaccount_name `
        --account-key $storageaccount_key `
        --name $container_name `
        --query exists 
}
catch {
    $_.Exception
}
# Skip container creation if it already exists
if ($containerCheck -eq "false") {
    Write-Host "Creating New Container: `"$container_name`"" -ForegroundColor Green
    try {
        az storage container create `
            --name $container_name `
            --account-name $storageaccount_name `
            --account-key $storageaccount_key `
            --public-access off
    }
    catch {
        Write-Output $_.Exception
    }
}
else {
    Write-Host "The container `"$container_name`" already exists" -ForegroundColor Red
}