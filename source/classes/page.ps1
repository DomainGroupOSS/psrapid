class page{

    [string]$filepath
    [hashtable] $links = @{}
    hidden [bool] $isFile
    hidden [string] $executePath
    hidden [string] $pathToReplace
    hidden [object] $targetFile
    hidden [int] $cacheTime
    hidden [bool] $cache
    hidden [bool] $auth
    hidden [array] $ipRanges
    hidden [array] $authGroups


    [object[]] $inputs

    page([string] $filepath,[string]$pageRef,[int]$defaultCacheTime,[bool]$defaultCacheBehaviour,[bool]$defaultAuthBehaviour)
    {
        $this.filepath = $filepath
        $this.links.this = $pageRef
        $this.cacheTime = $defaultCacheTime
        $this.cache = $defaultCacheBehaviour
        $this.auth = $defaultAuthBehaviour

        $endParent = if($pageRef[-1] -eq '/' -and $pageRef.length -gt 1){'/'}else{''}
        $this.links.parent = "/$($pageref.split('/')[-2])$endParent"
        try{
            $this.targetFile = get-item $filepath -ErrorAction stop
            if($this.targetFile.PSIsContainer -eq $true)
            {
                write-verbose 'Item is directory'
                $items = get-childitem $filepath -Recurse |where-object {$_.PsIsContainer -eq $true -or $_.Extension -eq '.ps1'}
                $this.pathToReplace = $this.targetFile.fullname
                if($this.pathToReplace[-1] -eq '\')
                {
                    $this.pathToReplace = $this.pathToReplace.Substring(0,$($this.pathToReplace.Length - 1))
                }
                $this.isFile = $false
                $this.getChildLinks($items)
            }elseif($this.targetFile.Extension -eq '.ps1'){
                write-verbose 'Item is file'
                $items = get-childItem $this.targetFile.Directory.FullName -Recurse | where-object {$_.PsIsContainer -eq $true -or $_.Extension -eq '.ps1' -and $_.FullName -ne $this.targetFile.fullname}
                $this.isFile = $true
                $this.pathToReplace = "$($this.targetFile.Directory.FullName)"
                
                $this.executePath = $this.targetFile.FullName
                $this.getChildLinks($items)
                $this.getInputs()
                $this.getAttribs()
            }else{
                Write-Warning 'Incorrect File Type'
            }

        }catch{
            write-warning 'unable to get the filepath'
        }

        

    }

    [void] getChildLinks($items)
    {
        write-verbose 'Get Child Links'
        Write-Verbose "Path to Replace: $($this.PathToReplace)"
        Write-Verbose "ParentPath: $($this.links.parent)"
        $children = foreach($item in $items)
        {
            if($item.PsIsContainer -eq $true)
            {
                $base = $item.fullname.replace($($this.PathToReplace),'')
                $basepath = "$($this.links.parent)$($base.replace('\','/'))/"
                if($basepath.substring(0,2) -eq '//')
                {
                    $basepath = $basepath.Substring(1)
                }
                
                write-verbose $basepath
                $basepath
                

            }else{
                $base = $item.Directory.fullname.replace($($this.PathToReplace),'')
                
                $base = $base.replace('\','/')
                Write-Verbose $base
                $basepath = "$($this.links.parent)$($base)/$($item.basename)"
                if($basepath.substring(0,2) -eq '//')
                {
                    $basepath = $basepath.Substring(1)
                }
                write-verbose $basepath
                $basepath
            }
            
            
        }
        Write-Verbose $($children | out-string)
        $this.links.children = $children
        
    }

    [void] getInputs()
    {
        write-verbose 'Get Inputs'
        try{
            $paramsBase = get-help  $this.executePath -Parameter * -ErrorAction Stop
            foreach($param in $paramsBase)
            {
                $this.inputs += [pscustomobject] @{
                    name = $param.name
                    description = $param.description.text
                    datatype = $param.type.name
                }

            }
        }catch{
            write-warning 'No Declared parameters'
        }
    }

    [void] getAttribs()
    {
        write-verbose 'Get Attribs'
        try{
            $command = get-command $this.executePath
            if($command)
            {
                $attribData = $command.ScriptBlock.Attributes|where-object{$_.typeid.name -eq 'PageControl'}
                if($attribData)
                {
                    write-verbose 'Got attrib data, adding to page details'
                    if($attribData.cacheMins)
                    {
                        write-verbose "Setting Cache Mins to: $($attribData.cacheMins)" 
                        $this.cacheTime = $attribData.cacheMins
                    }

                    if($attribData.cache -ne $null)
                    {
                        write-verbose "Setting Cache : $($attribData.cacheMins)" 
                        $this.cache = $attribData.cache
                    }

                    if($attribData.tokenRequired -ne $null)
                    {
                        write-verbose "Setting auth : $($attribData.tokenRequired)" 
                        $this.auth = $attribData.tokenRequired
                    }

                    if($attribData.networkRange)
                    {
                        $this.ipRanges = forEach($network in $attribData.networkRange)
                        {
                            write-verbose "Adding Netrange for : $network" 
                            $netData = [ipAssist]::new($network)
                            @{
                                first = $netData.firstIpAddress
                                last = $netData.lastIpAddress
                                min = $netData.startInteger
                                max = $netData.endInteger
                            }
                        }

                    }

                    if($attribData.authGroup)
                    {
                        $this.authGroups = $attribData.authGroup
                    }

                }else{
                    write-warning 'No attrib data found'
                }
                

            }else{
                write-warning 'Unable to get command data'
            }
        }catch{
            write-warning 'Unable to import command'
        }
    }
}