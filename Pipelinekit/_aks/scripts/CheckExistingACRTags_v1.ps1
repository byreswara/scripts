<# 
This script checks the target Azure Container Registry for a duplicate tag. If the Tag exists, the "Push Image to ACR" task will be skipped.
Currently, there is no way to pull a specific tag using Azure CLI commands. We have to pull all the tags for the repository and compare those tags to the image tag to push.
The script relies on the $(imageName), $(imageTag) and $(imageRepository) pipeline variables.
ACR Authentication is configured through Azure Resource Manager connection setting in this task.
#>
param(
    $imageRepository = '', # ACR Name
    $imageName = '', # Image Name
    $imageTag = '' # Image Tag
)

Write-Host "This script checks the target Azure Container Registry for a duplicate tag. If the Tag exists, the `"Push Image to ACR`" task will be skipped." `n
Write-Host "Checking Tags for $imageRepository/$imageName`:$imageTag" `n
Write-Host "Setting Skip Push Image to False" `n

$skip = $false
$acrtags = (az acr repository show-tags --name $imageRepository --repository $imageName --output jsonc) | ConvertFrom-Json

if(!$acrtags){
    Write-Host "No tags found in the ACR Repository: $imageRepository/$imageName" -ForegroundColor red
    Write-Host "##vso[task.setvariable variable=skipimagepush]$skip"
    exit
}
else {
    foreach ($tag in $acrtags) {
        Write-Host "Comparing Version tag to ACR Tag: $imagetag | $tag" `n
        if ($tag -ceq $imageTag) {
                Write-Host "This tag $tag already exists in the ACR; Skipping `"Image Push Task`"." -ForegroundColor red
                Write-Host "Setting Skip Push Image to True"
                $skip = $true
                Write-Host "##vso[task.setvariable variable=skipimagepush]$skip"
                exit
        }
        else {
            $skip = $false
            continue
        }
    }
}

Write-host "This tag $imagetag does not exists in the ACR; Proceeding with `"Image Push Task`"." -ForegroundColor green
Write-Host "##vso[task.setvariable variable=skipimagepush]$skip"
