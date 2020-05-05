[CmdletBinding()]
Param(
    [Parameter()]
    [string]$resourceGroupName = "web-deployment-test-rg",
    [Parameter()]
    [string]$webappname = "webapp-github-deployment-with-slots-" + $(Get-Random)
)

# Replace the following URL with a public GitHub repo URL
$gitrepo="https://github.com/realrubberduckdev/app-service-web-dotnet-get-started.git"
$location="UK South"

# Connect to Azure subscription
Connect-AzAccount

Get-AzResourceGroup -Name $resourceGroupName -ErrorVariable notPresent -ErrorAction SilentlyContinue
if ($notPresent)
{
    # Create a resource group.
    New-AzResourceGroup -Name $resourceGroupName -Location $location
}

# Create an App Service plan in Free tier.
New-AzAppServicePlan -Name $webappname -Location $location `
-ResourceGroupName $resourceGroupName -Tier Free

# Create a web app.
New-AzWebApp -Name $webappname -Location $location `
-AppServicePlan $webappname -ResourceGroupName $resourceGroupName

# Upgrade App Service plan to Standard tier (minimum required by deployment slots)
Set-AzAppServicePlan -Name $webappname -ResourceGroupName $resourceGroupName `
-Tier Standard

#Create a deployment slot with the name "staging".
New-AzWebAppSlot -Name $webappname -ResourceGroupName $resourceGroupName `
-Slot staging

# Configure GitHub deployment to the staging slot from your GitHub repo and deploy once.
$PropertiesObject = @{
    repoUrl = "$gitrepo";
    branch = "master";
}
Set-AzResource -PropertyObject $PropertiesObject -ResourceGroupName $resourceGroupName `
-ResourceType Microsoft.Web/sites/slots/sourcecontrols `
-ResourceName $webappname/staging/web -ApiVersion 2019-08-01 -Force

# Swap the verified/warmed up staging slot into production.
Switch-AzWebAppSlot -Name $webappname -ResourceGroupName $resourceGroupName `
-SourceSlotName staging -DestinationSlotName production