﻿Write-Host "
##############################################################################################################
#  _                         
# |_) _  __ __ _  _     _| _ 
# |_)(_| |  | (_|(_ |_|(_|(_|
#
# Script to deploy the Barracuda CloudGen Firewall into Microsoft Azure. This is a quickstart script which 
# also creates the network infrastructure needed for it.
#
##############################################################################################################

"

$location = Read-Host -Prompt 'Enter location (e.g. eastus2): '
if([string]::IsNullOrEmpty($location)) {            
  $location = "eastus2"
}
Write-Host "
--> Deployment in $location location ...
"

$prefix = Read-Host -Prompt 'Enter prefix: '
if([string]::IsNullOrEmpty($prefix)) {            
  $location = "CUDA"
}
Write-Host "
--> Using prefix $prefix for all resources location ...
"

$rg="$prefix-RG"

$password = Read-Host -AsSecureString 'Enter password
!! BEWARE: Password complexity rules 12 characters, [A-Za-z0-9] and special char !!' 

Write-Host "`nCreating $rg resource group ..."
New-AzureRMResourceGroup -Name $rg -Location "$location"

Write-Host "`nValidationg deployment in $rg resource group ..."
Test-AzureRmResourceGroupDeployment -ResourceGroupName "$rg" `
    -TemplateFile "azuredeploy.json" -TemplateParameterFile "azuredeploy.parameters.json" `
    -adminPassword $password -prefix $prefix 

Write-Host "`nDeployment of $rg resources ..."
New-AzureRMResourceGroupDeployment -Name "Deploy_$rg" -ResourceGroupName "$rg" `
    -TemplateFile "azuredeploy.json" -TemplateParameterFile "azuredeploy.parameters.json" `
    -adminPassword $password -prefix $prefix

$cgfipaddress = (Get-AzureRMPublicIpAddress -ResourceGroup $rg -Name "$prefix-VM-CGF-A-PIP").IpAddress

mkdir -p ansible/inventory/
$ansibleinventory = @"
[cgf]
$prefix-VM-CGF-A ansible_host=$cgfipaddress ansible_port=8443 ansible_connection=local gather_facts=no

[cgf-group:children]
cgf
"@ | Out-File -FilePath ansible/inventory/all

Write-Host "`nAnsible configuration of CloudGen Firewall cluster"
ansible-playbook ansible/all.yml -i "ansible/inventory/all" --extra-vars "cgf_prefix=$prefix cgf_password=$passwd"

Write-Host "
##############################################################################################################
#  _                         
# |_) _  __ __ _  _     _| _ 
# |_)(_| |  | (_|(_ |_|(_|(_|
#
# Thank you for deploying the Barracuda CloudGen Firewall for more information:
#
# Campus website:
# https://campus.barracuda.com/product/cloudgenfirewall/doc/73719655/microsoft-azure-deployment/
#
# Connect via email:
# azure_support@barracuda.com
#
##############################################################################################################
"
