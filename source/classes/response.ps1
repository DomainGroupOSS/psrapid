class response{

    [hashtable] $links
    [object[]] $inputs
    [int] $itemCount
    [object[]] $items
    [string]$server = 'psRapid'
    [string]$timestamp = $(get-date -format s)
    [bool]$cachedResponse = $false
    

    respones()
    {

        $objType = $this.GetType()
        if($objType -eq [response])
        {
            throw "Parent Class $($objType.Name) Must be inherited"
        }

    }

    [string] json()
    {
        return $this|ConvertTo-Json -depth 10
    }

    [void] fromCache()
    {
        $this.timestamp = $(get-date -format s)
        $this.cachedResponse = $true
    }

}

class pageResponse : response
{
    pageResponse([object]$page,[object]$script)
    {
        $this.links = $page.links
        $this.inputs = $page.inputs
        if($script.results)
        {
            $this.itemCount = $($script.results |measure-object).count
            $this.items = $script.results
        }else{
            $this.itemCount = 0
            $this.items = $null
        }
       
    }
}

class adminResponse : response
{
    
    adminResponse($items,$links,$inputs)
    {
        $this.links = $links
        $this.items = $items
        $this.itemcount = $($items |measure-object).count
        $this.inputs = $inputs
    }


}

class accessDeniedResponse : response
{

}