# This script will check for an existing application insights resource group and workspace in each environment and create them if they do not exist.

# Set environment and location variables
$env = @("qa", "uat", "prod")
$location = "centralus"
$deployer = "Mathew Ashley"
$time = [Xml.XmlConvert]::ToString((Get-Date), [Xml.XmlDateTimeSerializationMode]::Utc)
$sku = "PerGB2018"
###############################
#         Main Script         #
###############################

# Loop throuch each environment and create the application insights resource group and workspace
foreach($env in $envs){
    # Set the resource group name
    $ai_rg = "rg-ai-$env"
    $ai_workspace = "workspace-es-$env"

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
        "CreationDate=$time"
    )

    # Set the subscription
    az account set -s $SubscriptionID

    # Check for existing resource group or create new
    $rgCheck = az group exists --name $ai_rg
    if ($rgCheck -ne $true) {
        Write-Host "Creating Resource Group" -ForegroundColor green    
        az group create `
            --name $ai_rg `
            --location $location `
            --tags $tags
        Start-Sleep 10
        $rgCheck = az group exists --name $ai_rg
    }
    else {
        Write-Host "The resource group: `"$ai_rg`" already exists" -ForegroundColor yellow
    }

    # Create the workspace
    az monitor log-analytics workspace create `
        --resource-group $ai_rg `
        --workspace-name $ai_workspace `
        --location $location `
        --sku $sku `
        --tags $tags
}