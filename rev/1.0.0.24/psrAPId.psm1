<#
Module Mixed by BarTender
	A Framework for making PowerShell Modules
	Version: 6.1.22
	Author: Adrian.Andersson
	Copyright: 2019 Domain Group

Module Details:
	Module: psrAPId
	Description: A PowerShell API Framework
	Revision: 1.0.0.24
	Author: Adrian Andersson
	Company: Domain Group

Check Manifest for more details
#>

function get-urlDecode
{
    [CmdletBinding()]
    param(
        [string]$url
    )
    try{
        $webUtility =  [System.Web.HttpUtility]
    }catch{
        Write-Verbose 'Assembly not loaded, attempting to load'
        Add-Type -AssemblyName system.web
        $webUtility = [System.Web.HttpUtility]
    }
    
    $webUtility::UrlDecode($url)
}
function get-urlEncode
{
    [CmdletBinding()]
    param(
        [string]$url
    )
    try{
        $webUtility =  [System.Web.HttpUtility]
    }catch{
        Write-Verbose 'Assembly not loaded, attempting to load'
        Add-Type -AssemblyName system.web
        $webUtility = [System.Web.HttpUtility]
    }
    $webUtility::urlEncode($url)
}

