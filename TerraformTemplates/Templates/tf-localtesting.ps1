$module = "aks_template/v1"
$modulePath = ".\custom_modules\$module"

$stage = 'qa'
$serviceName = 'test'
$storageaccount_name = 'sttctfqacus001'
$storageaccount_rg = 'rg-terraform-qa'
$container_name = "aks-$ServiceName-qa-tf"
$env:TF_BACKEND_KEY = 'aks-test2-tf'

Switch ($stage) {
    'prod' {
        Write-Host 'You Chose PROD Environment' -ForegroundColor Red `n
        $env:TF_BACKEND_RG = $storageaccount_rg
        $env:TF_BACKEND_ACCESS_KEY = ''
        $env:SubscriptionID = '5429f7aa-0e72-4bdb-a036-328ffc0674fa'
        $env:TF_BACKEND_STORAGE_ACCOUNT = $storageaccount_name
        $env:TF_BACKEND_CONTAINER = $container_name
    }
    'uat' {
        Write-Host 'You Chose UAT Environment' -ForegroundColor Yellow `n
        $env:TF_BACKEND_RG = $storageaccount_rg
        $env:TF_BACKEND_ACCESS_KEY = ''
        $env:SubscriptionID = '50bc17fa-ab53-4515-8150-3338c2e9840f'
        $env:TF_BACKEND_STORAGE_ACCOUNT = $storageaccount_name
        $env:TF_BACKEND_CONTAINER = $container_name
    }
    'qa' {
        Write-Host 'You Chose QA Environment' -ForegroundColor Green `n
        $env:TF_BACKEND_RG = $storageaccount_rg
        $env:TF_BACKEND_ACCESS_KEY = ''
        $env:SubscriptionID = '9b28bd6c-83d4-4721-b1e9-cec8810ab5f9'
        $env:TF_BACKEND_STORAGE_ACCOUNT = $storageaccount_name
        $env:TF_BACKEND_CONTAINER = $container_name
    }

}

# Uncomment to enable trace logging: TRACE , DEBUG , INFO , WARN , ERROR and FATAL. Default is warn.
# $env:TF_LOG="warn"

# Set Working directory
$wdr = split-path -Parent $MyInvocation.MyCommand.Definition
Set-Location $wdr\$modulePath

az account set -s $env:SubscriptionID
$containerCheck = $null
try {
    $containerCheck = az storage container exists `
        --account-name $env:TF_BACKEND_STORAGE_ACCOUNT `
        --account-key $env:TF_BACKEND_ACCESS_KEY `
        --name $env:TF_BACKEND_CONTAINER `
        --query exists 
}
catch {
    $_.Exception
}
# Skip container creation if it already exists
if ($containerCheck -eq 'false') {
    Write-Host "Creating New Container: `"$env:TF_BACKEND_CONTAINER`"" -ForegroundColor Green
    try {
        az storage container create `
            --name $env:TF_BACKEND_CONTAINER `
            --account-name $env:TF_BACKEND_STORAGE_ACCOUNT `
            --account-key $env:TF_BACKEND_ACCESS_KEY `
            --public-access off
    }
    catch {
        Write-Output $_.Exception
    }
}
else {
    Write-Host "The container `"$env:TF_BACKEND_CONTAINER`" already exists" -ForegroundColor Red
}

Write-Host $env:TF_BACKEND_RG $env:TF_BACKEND_STORAGE_ACCOUNT $env:TF_BACKEND_CONTAINER
terraform init `
    -backend-config="resource_group_name=$env:TF_BACKEND_RG" `
    -backend-config="storage_account_name=$env:TF_BACKEND_STORAGE_ACCOUNT" `
    -backend-config="container_name=$env:TF_BACKEND_CONTAINER" `
    -backend-config="key=$env:TF_BACKEND_KEY" `
    -input="true" `
    -reconfigure
terraform validate
terraform plan  `
    -out="./tfplan" `
    -var-file="./vars/example.tfvars" `
    -refresh="true"
terraform apply `
    -refresh=true `
    -auto-approve `
    ./tfplan
# terraform destroy `
#     -refresh=true `
#     -var-file="./vars/example.tfvars" `
#     -auto-approve
