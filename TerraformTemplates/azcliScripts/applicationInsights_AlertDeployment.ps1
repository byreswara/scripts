# Requires azure cli. If running locally, use az login first. Pipelines should use ServiceConnections.

#############
# Variables #
#############

# Target Environment
$stage = 'qa'

# Global AppInsights variables
$ai_workspace = "workspace-es-$stage"
$ai_rg = "rg-ai-$stage"

# Global Storage Account variables
$storageaccount_rg = "rg-terraform-$stage"
$storageaccount_name = "sttctf$stage`cus001"
$alert_enabled = "false"


Switch ($stage) {
    'prod' {
        Write-Host 'You Chose PROD Environment' -ForegroundColor Red `n
        $env:TF_BACKEND_RG = $storageaccount_rg
        $env:TF_BACKEND_KEY = ''
        $env:SubscriptionID = '5429f7aa-0e72-4bdb-a036-328ffc0674fa'
        $env:TF_BACKEND_STORAGE_ACCOUNT = $storageaccount_name
    }
    'uat' {
        Write-Host 'You Chose UAT Environment' -ForegroundColor Yellow `n
        $env:TF_BACKEND_RG = $storageaccount_rg
        $env:TF_BACKEND_KEY = ''
        $env:SubscriptionID = '50bc17fa-ab53-4515-8150-3338c2e9840f'
        $env:TF_BACKEND_STORAGE_ACCOUNT = $storageaccount_name
    }
    'qa' {
        Write-Host 'You Chose QA Environment' -ForegroundColor Green `n
        $env:TF_BACKEND_RG = $storageaccount_rg
        $env:TF_BACKEND_KEY = ''
        $env:SubscriptionID = '9b28bd6c-83d4-4721-b1e9-cec8810ab5f9'
        $env:TF_BACKEND_STORAGE_ACCOUNT = $storageaccount_name
    }
}

###############
# Main Script #
###############

# Set account to specified subscription
az account set -s $env:SubscriptionID

# Collect Application Insights instances
$ailist = az monitor app-insights component show --resource-group $ai_rg --query '[].{Name:name,ResourceId:id}'
$ailist = $ailist | ConvertFrom-Json
$ailist = $ailist | sort-object name

foreach ($name in $ailist.name) {
    $output += Write-Host 'Updating:' $name `n -ForegroundColor Green
    if ($name -match "ai-(.*?)-$stage") { 
        $serviceName = $matches[1] 
    }

    $ai_name = $name
    $container_name = "ai-$serviceName-$stage-tf"
    $container_name = $container_name.ToLower()
    $ai_alert = "alert-$serviceName-$stage"
    
    $env:TF_BACKEND_CONTAINER = $container_name
    $containerCheck = (az storage container exists `
            --account-name $storageaccount_name `
            --account-key $env:TF_BACKEND_KEY `
            --name $container_name `
            --query exists | ConvertFrom-Json) 2>&1

    $output += Write-Host 'Variable Checklist:' `n `
        '=====================================================================================' `n `
        'backend rg:' $env:TF_BACKEND_RG `n `
        'backend storage account:' $env:TF_BACKEND_STORAGE_ACCOUNT `n `
        'backend container:' $env:TF_BACKEND_CONTAINER `n `
        'stage:' $stage `n `
        'location:' $env:LOCATION `n `
        'project:' $env:PROJECT_NAME `n `
        'subscription id:' $env:SubscriptionID `n `
        'ai rg:' $ai_rg `n `
        'ai name:' $ai_name `n `
        'ai alert:' $ai_alert `n `
        'ai workspace:' $ai_workspace `n `
        'container check:' $containerCheck `n `
        '=====================================================================================' `n -ForegroundColor yellow
try {
        $terraformoutput = terraform init `
            -backend-config="resource_group_name=$env:TF_BACKEND_RG" `
            -backend-config="storage_account_name=$env:TF_BACKEND_STORAGE_ACCOUNT" `
            -backend-config="container_name=$env:TF_BACKEND_CONTAINER" `
            -backend-config="key=$env:TF_BACKEND_KEY" `
            -input="true" `
            -reconfigure
        $output += $terraformoutput

        # $terraformoutput = terraform plan  `
        #     -out="./tfplan" `
        #     -var="environment_name=$STAGE" `
        #     -var="location=$env:LOCATION" `
        #     -var="project_name=$env:PROJECT_NAME" `
        #     -var="subsriptionId=$env:SubscriptionID" `
        #     -var="ai_rg=$ai_rg" `
        #     -var="ai_name=$ai_name" `
        #     -var="ai_alert=$ai_alert" `
        #     -var="alert_enabled=$alert_enabled" `
        #     -var="workspace_name=$ai_workspace" `
        #     -var="tenantId=e19ce0fc-2429-4a9e-b937-3ef24246c22c" `
        #     -refresh=true `
        #     -lock=false
        # $output += $terraformoutput

        # $terraformoutput = terraform apply `
        #     -refresh=true `
        #     -auto-approve `
        #     ./tfplan
        # $output += $terraformoutput
}
catch {
    $_.Exception.Message
}

} 

$output | out-file -FilePath "c:\temp\ai_alert_deployment_$stage.log"
