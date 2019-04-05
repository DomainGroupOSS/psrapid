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