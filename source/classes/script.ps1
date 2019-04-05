class script
{
    [object[]]$results
    [hashtable]$params
    [string]$filepath

    script([string]$filepath,[hashtable]$params)
    {
        $this.filepath = $filepath
        $this.params = $params
        try{
            $file = get-item $this.filepath -ErrorAction stop
        }catch{
            Write-warning 'File not Found'
            $file = $null
        }

        if(($file -and $file.Extension -eq '.ps1'))
        {
            $this.execute()


        }else{
            write-warning 'Invalid FileType'
        }
        
        
    }

    [void] execute()
    {
        if($this.params.count -gt 0)
        {
            write-verbose 'Executing with params'
            $splat = $this.params
            $scriptResult = . $this.filepath @splat
        }else{
            write-verbose 'Executing wihtout params'
            $scriptResult = . $this.filepath
        }

        if($scriptResult)
        {
            Write-Verbose 'Saving Results'
            $this.results = $scriptResult
        }else{
            Write-Verbose 'No Results returned'

        }


    }
}