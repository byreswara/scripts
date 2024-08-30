param(
    [Parameter(Mandatory = $true)]
    [string]$ai_stagingdirectory
)

if (Test-Path -Path "$ai_stagingdirectory/ai_variables.json" -PathType Leaf ) {
    Write-Output 'ai_variables.json was found. Proceeding to set pipeline variables for application insights.'
    $ai_variables = Get-Content -Raw -Path "$ai_stagingdirectory/ai_variables.json"

    Write-Output 'Found the following values from the application insights variable file:'

    $ai_variables

    $ai_variables = $ai_variables | ConvertFrom-Json

    $instrumentationkey = $ai_variables.instrumentationkey
    $resourceId = $ai_variables.resourceid
    $connectionstring = $ai_variables.connectionString

    Write-Host "##vso[task.setvariable variable=ApplicationInsights.InstrumentationKey;]$instrumentationkey"
    Write-Host "##vso[task.setvariable variable=ApplicationInsights:InstrumentationKey;]$instrumentationkey"

    Write-Host "##vso[task.setvariable variable=ApplicationInsights.aiResourceId;]$resourceId"
    Write-Host "##vso[task.setvariable variable=ApplicationInsights:aiResourceId;]$resourceId"

    Write-Host "##vso[task.setvariable variable=ApplicationInsights.connectionString;]$connectionString"
    Write-Host "##vso[task.setvariable variable=ApplicationInsights:connectionString;]$connectionString"
}
else {
    Write-Output 'ai_variables.json was not found. Existing Script.'
    Exit
}