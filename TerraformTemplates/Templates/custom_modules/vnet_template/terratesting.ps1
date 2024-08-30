$environment = "qa"
$location = "centralus"
$location_short = "cus"
$serviceName = "testing"
$storageaccount_name = "sttctfqacus001"
$storageaccount_rg = "rg-terraform-qa"
$vnet_iteration = "02"
$container_name = "vnet-$ServiceName-qa-tf-$vnet_iteration"
$subscription = "qa"
$resource_group_name = "rg-terratesting-qa"

$env:TF_BACKEND_RG = $storageaccount_rg
$env:TF_BACKEND_KEY = "2zQgLl7vVHjSnsN/o3k3iqCWVKuLciqSM6o5yNvDje9fVZAn7bzdHUAGy1L/C6Z2D1gNFUcpyDsZ+AStDDhWBg=="
$env:SubscriptionID = "9b28bd6c-83d4-4721-b1e9-cec8810ab5f9"
$env:TF_BACKEND_STORAGE_ACCOUNT = $storageaccount_name
$env:TF_BACKEND_CONTAINER = $container_name

# Uncomment to enable trace logging: TRACE , DEBUG , INFO , WARN , ERROR and FATAL. Default is warn.
#$env:TF_LOG="warn"

az account set -s $env:SubscriptionID
az account list
Write-Host $env:TF_BACKEND_RG $env:TF_BACKEND_STORAGE_ACCOUNT $env:TF_BACKEND_CONTAINER
terraform init `
    -backend-config="resource_group_name=$env:TF_BACKEND_RG" `
    -backend-config="storage_account_name=$env:TF_BACKEND_STORAGE_ACCOUNT" `
    -backend-config="container_name=$env:TF_BACKEND_CONTAINER" `
    -backend-config="key=$env:TF_BACKEND_KEY" `
    -input="true" `
    -reconfigure
terraform plan  `
    -out="./tfplan" `
    -var-file="./vars/$environment.tfvars" `
    -var="subscription=$Subscription" `
    -var="environment=$environment" `
    -var="location=$location" `
    -var="location_short=$location_short" `
    -var="vnet_iteration=$vnet_iteration" `
    -var="resource_group_name=$resource_group_name" `
    -refresh="true" `
    -lock="false"
    # -var="subsriptionId=$env:SubscriptionID"
    # -var="tenantId=e19ce0fc-2429-4a9e-b937-3ef24246c22c" `
    # -refresh="true" `
    # -lock="false"
terraform apply `
    -refresh=true `
    -auto-approve `
    ./tfplan