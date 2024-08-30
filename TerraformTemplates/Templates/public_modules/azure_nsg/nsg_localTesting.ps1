param(
	$stage = "qa"
)

$serviceName = "localtesting"
$storageaccount_name = "sttctf$stage`cus001"
$storageaccount_rg = "rg-terraform-$stage"
$container_name = "nsg-$ServiceName-$stage-tf"

Switch ($stage) {
	"prod" {
		Write-Host "You Chose PROD Environment"
		$env:TF_BACKEND_RG = $storageaccount_rg
		$env:TF_BACKEND_KEY = ""
		$env:SubscriptionID = "5429f7aa-0e72-4bdb-a036-328ffc0674fa"
		$env:TF_BACKEND_STORAGE_ACCOUNT = $storageaccount_name
		$env:TF_BACKEND_CONTAINER = $container_name
	}
	"uat" {
		Write-Host "You Chose UAT Environment"
		$env:TF_BACKEND_RG = $storageaccount_rg
		$env:TF_BACKEND_KEY = ""
		$env:SubscriptionID = "50bc17fa-ab53-4515-8150-3338c2e9840f"
		$env:TF_BACKEND_STORAGE_ACCOUNT = $storageaccount_name
		$env:TF_BACKEND_CONTAINER = $container_name
	}
	"qa" {
		Write-Host "You Chose QA Environment"
		$env:TF_BACKEND_RG = $storageaccount_rg
		$env:TF_BACKEND_KEY = ""
		$env:SubscriptionID = "9b28bd6c-83d4-4721-b1e9-cec8810ab5f9"
		$env:TF_BACKEND_STORAGE_ACCOUNT = $storageaccount_name
		$env:TF_BACKEND_CONTAINER = $container_name
	}

}

# Uncomment to enable trace logging: TRACE , DEBUG , INFO , WARN , ERROR and FATAL. Default is warn.
#$env:TF_LOG="warn"
# cd ./applicationinsights

$env:LOCATION = "centralus"
$env:PROJECT_NAME = "Enterprise Services"

# Check if current working directory is applicationinsights

# Trim $pwd.path to only include last part of the string

az account set -s $env:SubscriptionID
#az account list
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
	-refresh=true `
	-lock=false
terraform apply `
	-refresh=true `
	-auto-approve `
	./tfplan

