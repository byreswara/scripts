# Requires azure cli. If running locally, use az login first. Pipelines should use ServiceConnections.

param (
    [Parameter(Mandatory = $true)]
    [string]$SubscriptionID,
    [Parameter(Mandatory = $true)]
    [string]$ApplicationInsights_rg,
    [Parameter(Mandatory = $true)]
    [string]$ApplicationInsights_name,
    [Parameter(Mandatory = $false)]
    [string]$AI_StagingDirectory
)

###############################
# Variables for local testing #
###############################

# $SubscriptionID = "9b28bd6c-83d4-4721-b1e9-cec8810ab5f9"
# $ApplicationInsights_rg = "rg-qa-ai"
# $ApplicationInsights_name = "ai-claim-qa"

###############################
#         Main Script         #
###############################

# Collection Application Insights data: Set target Subscription, Install AppInsights extension, collect metadata.
az account set -s $SubscriptionID
az config set extension.use_dynamic_install=yes_without_prompt --only-show-errors
$aimeta = az monitor app-insights component show `
    --app $ApplicationInsights_name `
    --resource-group $ApplicationInsights_rg `
    --subscription $SubscriptionID  | ConvertFrom-Json

$instrumentationkey = $aimeta.InstrumentationKey
$resourceId = $aimeta.id
$connectionString = $aimeta.ConnectionString

# Output for log
Write-Host "InstrumentationKey:" $instrumentationkey
Write-Host "ResourceId:" $resourceId
Write-Host "ConnectionString:" $connectionString

# Set ApplicationInsights Pipeline Variables 
Write-Host "##vso[task.setvariable variable=ApplicationInsights.InstrumentationKey;]$instrumentationkey"
Write-Host "##vso[task.setvariable variable=ApplicationInsights:InstrumentationKey;]$instrumentationkey"

Write-Host "##vso[task.setvariable variable=ApplicationInsights.aiResourceId;]$resourceId"
Write-Host "##vso[task.setvariable variable=ApplicationInsights:aiResourceId;]$resourceId"

Write-Host "##vso[task.setvariable variable=ApplicationInsights.connectionString;]$connectionString"
Write-Host "##vso[task.setvariable variable=ApplicationInsights:connectionString;]$connectionString"

# Set ApplicationInsights Pipeline Variables for Jobs (yaml only - needs testing)
Write-Host "##vso[task.setvariable variable=ApplicationInsights.InstrumentationKey;isOutput=true;]$instrumentationkey"
Write-Host "##vso[task.setvariable variable=ApplicationInsights:InstrumentationKey;isOutput=true;]$instrumentationkey"

Write-Host "##vso[task.setvariable variable=ApplicationInsights.aiResourceId;isOutput=true;]$resourceId"
Write-Host "##vso[task.setvariable variable=ApplicationInsights:aiResourceId;isOutput=true;]$resourceId"

Write-Host "##vso[task.setvariable variable=ApplicationInsights.connectionString;isOutput=true;]$connectionString"
Write-Host "##vso[task.setvariable variable=ApplicationInsights:connectionString;isOutput=true;]$connectionString"

# Output variables to json file for deployment group consumption
$ai_variables = @{
    "instrumentationKey" = $instrumentationkey
    "aiResourceID" = $resourceId
    "connectionString" = $connectionString
}

if ($null -ne $ai_stagingDirectory){
    $ai_variables | ConvertTo-Json | Out-File -FilePath "$ai_stagingDirectory/ai_variables.json"
}