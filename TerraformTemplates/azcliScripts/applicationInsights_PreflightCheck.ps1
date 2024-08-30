# Requires azure cli. If running locally, use az login first. Pipelines should use ServiceConnections.

param (
    # Parameter help description
    [Parameter(Mandatory = $true)]
    [String]$serviceName, # $(ServiceName)
    [Parameter(Mandatory = $true)]
    [string]$EnvironmentName, # $(EnvironmentName)
    [Parameter(Mandatory = $true)]
    [string]$SubscriptionID, # $(SubscriptionID)
    [Parameter(Mandatory = $true)]
    [string]$container_name, # "ai-$ServiceName-$EnvironmentName-tf"
    [Parameter(Mandatory = $true)]
    [string]$storageaccount_name, # "stterraform$EnvironmentName`cus001"
    [Parameter(Mandatory = $true)]
    [string]$storageaccount_key, # $(storageaccount_key) #This should be kept secret in pipelines
    [Parameter(Mandatory = $true)]
    [string]$ApplicationInsights_rg, # $(appinsights_ResourceGroup)
    [Parameter(Mandatory = $true)]
    [string]$ApplicationInsights_name # $(appinsights_Name)
)

###############################
# Variables for local testing #
###############################

# $SubscriptionID = "9b28bd6c-83d4-4721-b1e9-cec8810ab5f9"
# $container_name = "ai-EnrollmentV2-qa-tf"
# $storageaccount_name = "sttctfqacus001"
# $storageaccount_key = ""
# $ApplicationInsights_rg = "rg-qa-ai"
# $ApplicationInsights_name = "ai-EnrollmentV2-qa"

###############################
#         Main Script         #
###############################

# Convert variable $container_name to lowercase
$container_name = $container_name.ToLower()
$EnvironmentName = $EnvironmentName.toLower()
# Set account to specified subscription
az account set -s $SubscriptionID
$containerCheck = $null
Write-Host "Checking for existing backend container for terraform: `"$container_name`"" -ForegroundColor Green
$containerCheck = (az storage container exists `
        --account-name $storageaccount_name `
        --account-key $storageaccount_key `
        --name $container_name `
        --query exists | convertfrom-json) 2>&1

# Skip container creation if it already exists
if ($containerCheck -eq $false) {
    Write-Host "Creating new terraform container: `"$container_name`"" -ForegroundColor Green
    az storage container create `
        --name $container_name `
        --account-name $storageaccount_name `
        --account-key $storageaccount_key `
        --public-access off
}
elseif ($containerCheck -eq $true) {
    Write-Host "The terraform container `"$container_name`" already exists" -ForegroundColor Yellow
}
else {
    Throw $containerCheck
}

# Output variable container_name as lowercase to a pipeline variable for the terraform init step
Write-Host "##vso[task.setvariable variable=tfbackend.container.ai;]$container_name"

# Config set and extension add outputs WARNING messages to the stderr stream. These are not errors, and we don't need to know about them, added --only-show-errors to suppress them.
az config set extension.use_dynamic_install=yes_without_prompt --only-show-errors
az extension add -n application-insights --only-show-errors

# Check for existing application insights, send output variable to pipeline
# PS does not inherently interpret az cli errors. $errOutput variable captures the warnings and errors to be used later as we want to know about them.
# 2>&1 expression is used to redirect the standard error (the 2) to the same place as standard output (the 1)
Write-Host "Searching for existing Application Insights Instance..."
$errOutput = ($ai = az monitor app-insights component show `
        --app $ApplicationInsights_name `
        --resource-group $ApplicationInsights_rg `
        --subscription $SubscriptionID | convertfrom-json) 2>&1

if (($EnvironmentName -eq "prod") -or ($EnvironmentName -eq "production")){
    Write-Host "Environment is production. Running terraform to enable/disable alert."
    Write-Host "##vso[task.setvariable variable=aiExists;]$false"
    break
}
elseif ($errOutput -like '*(ResourceNotFound)*') {
    Write-Host "Application Insights instance does not exist. Proceeding with Deployment"
    Write-Host "##vso[task.setvariable variable=aiExists;]$false"
    $LASTEXITCODE = 0
    break
}
elseif ($ai.provisioningState -eq "Succeeded") {
    Write-Host "Applicaiton Insights Instance already exists."
    $ai
    Write-Host "##vso[task.setvariable variable=aiExists;]$true"
    break
}
else {
    Throw $errOutput
}