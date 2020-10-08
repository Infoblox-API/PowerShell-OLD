#Requires -Version 7.0

### Sample PowerShell Script for BloxOne DDI
### Author:  Don Smith
### Author-Email: dsmith@infoblox.com

Using module ".\Class\bloxonesession.psm1"
Using module ".\Class\bloxone.psm1"
$VerbosePreference = 'continue'
#$VerbosePreference = 'SilentlyContinue'

# Remove old functions/Cmdlets from the current module
Write-Output "Removing old instances of functions"
Get-Module BloxOne-DDI | Remove-Module
clear

# Load the current module
Import-Module “.\BloxOne-DDI.psd1”


#--------------------
# Test Code
#--------------------

<#
# Create a reusable session
$session1 = [BloxOneSession]::New("***api_key***")
$session1
#>

Write-Output "<<----- [ddi1] ---------------------------------------->>"
Write-Output "DDI object with INI file and section"
$ddi1 = [DDI]::New("bloxone.ini", "Sandbox")

# Create a new object
$newObjJson = "{ ""name"":""delete_me"", ""comment"":""Created via PowerShell script"" }"
$newObjType = "/ipam/ip_space"
$ddi1.CreateRequest($newObjType, $newObjJson)

# Retrieve the object
$ddi1_args = "_fields=name,comment,id,tags&_filter=name==""delete_me"""
$ddi1.GetRequest("/ipam/ip_space", $ddi1_args)
$objID = $ddi1.result[0].id

# Update the object
$newObjJson = "{ ""name"":""patched_me"", ""comment"":""Updated via PowerShell script"" }"
$ddi1.UpdateRequest($objID, $newObjJson)

# Delete the object
$ddi1.DeleteRequest($objID)
