class adminPage{

    [string] $page
    [hashtable[]] $requestParams
    [hashtable] $links 
    [object] $response
    [string] $tokensPath
    [string] $currentToken
    hidden [string] $adminCommand




    adminPage($page,$requestParams,$tokensPath,$currentToken)
    {
        $this.requestParams = $requestParams
        $this.page = $page
        $this.tokensPath = $tokensPath
        $this.currentToken = $currentToken
        
        switch -Wildcard ($this.page)
        {
            '/stop' {$this.stop()}

            '/clearcache' {$this.clearcache()}

            "/user*" {$this.user()}

            default {$this.default()}
        }
        

    }


    [void] makeLinks([string]$thisPage,[array]$children)
    {
        $this.links = @{
            this = $thisPage
            children = $children
            parent = '/admin'
        }

        
    }

    [void] stop()
    {
        $this.adminCommand = 'stop'
        $this.makeLinks('/admin/stop',$null)
        $items = [pscustomobject] @{
            message = 'Server requested to stop listening'
        }

        #$this.response = New-Object adminResponse -ArgumentList ($items,$this.links,$null)
        $this.response = [adminResponse]::NEW($items,$this.links,$null)
    }


    [void] clearcache()
    {
        $this.adminCommand = 'clearcache'
        $this.makeLinks('/admin/clearcache',$null)
        $items = [pscustomobject] @{
            message = 'Clear Cache Initialised'
        }
        #$this.response = New-Object adminResponse -ArgumentList ($items,$this.links,$null)
        $this.response = [adminResponse]::NEW($items,$this.links,$null)
    }

    [void] default()
    {
        $children = @(
            '/stop',
            '/user/',
            '/user/new',
            '/user/disable',
            '/user/enable',
            '/user/revokeAdmin'
            '/user/grantAdmin'
            '/user/get',
            '/clearcache'

        )

        $this.makeLinks('/admin/',$children)
        $this.links.parent = '/'

        #$this.response = New-Object adminResponse -ArgumentList ($null,$this.links,$null)
        $this.response = [adminResponse]::NEW($null,$this.links,$null)
        
    }

    [void] user()
    {
        switch ($this.page)
        {
            '/user/new' {
                $inputs = @(

                    [pscustomobject] @{
                        name = 'username'
                        description = 'The associated username'
                        datatype = 'string'
                    },
                    [pscustomobject] @{
                        name = 'isadmin'
                        description = 'Should the user have elevated rights'
                        datatype = 'bool'
                    }
                )

                $this.makeLinks('/admin/user/new',$null)

                $username = $this.requestParams.username
                if($username)
                {
                    $adminValue = $this.requestParams.isAdmin
                    $acceptedValues = @(1,'true','yes','t','y')
                    try{
                        $currentTokens = Import-Clixml $this.tokensPath -ErrorAction Stop
                        if($($currentTokens|measure-Object).count -eq 1 )
                        {
                            #We have a single item and we need an array
                            write-verbose 'Converting To Array'
                            $currentTokens = @($currentTokens)
                        }
                    }catch{
                        $currentTokens = @()
                    }
                    

                    if($adminValue -in $acceptedValues)
                    {
                        write-verbose "$username will be created with Admin access"
                        $admin = $true
                    }else{
                        write-verbose "$username will be created with Std access"
                        $admin = $false
                    }
                    try{
                        
                        write-verbose 'Got the tokens'
                        $guid = $(new-guid).Guid
                        $h = [pscustomobject]@{event='created';by="$($this.currentToken)";date="$(get-date -format s)"}
                        write-verbose 'Making user object'
                        $newUser = [pscustomobject] @{
                            token = $guid
                            username = $username
                            isadmin = $admin
                            history = [array] @($h)
                            enabled = $true
                        }
                        write-verbose 'Adding Token to the list'
                        
                        $currentTokens += $newUser #Look, I know this is not the best way, but it works
                        write-verbose $($currentTokens|ConvertTo-Json -Depth 2)
                        write-verbose 'Exporting'
                        $currentTokens|Export-Clixml $this.tokensPath -Force
                        $this.adminCommand = 'updateUsers'
                        
                    }catch{
                        $currentTokens = $null
                        write-verbose 'DID NOT GET THE TOKENS'
                        $newUser = $null
                    }
                    


                }else{
                    $newUser = $null
                }

                #$this.response = new-object adminResponse -ArgumentList ($newUser,$this.links,$inputs)
                $this.response = [adminResponse]::NEW($newUser,$this.links,$inputs)

            }
            '/user/disable' {
                $inputs = @(

                    [pscustomobject] @{
                        name = 'username'
                        description = 'The username - to disable all associated tokens'
                        datatype = 'string'
                    },
                    [pscustomobject] @{
                        name = 'token'
                        description = 'Token to disable - not used if Username is specified'
                        datatype = 'string'
                    }
                )

                $this.makeLinks('/admin/user/disable',$null)

                $username = $this.requestParams.username
                $token = $this.requestParams.token
                if($username)
                {
                    $currentTokens = Import-Clixml $this.tokensPath
                    $return = foreach($user in $currentTokens)
                    {
                        if($user.username -eq $username)
                        {
                            $user.enabled = $false
                            $user.history += [pscustomobject]@{event='disabled';by=$this.currentToken;date=$(get-date -format s)}
                            $user
                        }
                    }
                    $currentTokens | Export-Clixml $this.tokensPath -Force
                }elseIf($token){
                    $currentTokens = Import-Clixml $this.tokensPath
                    $return = foreach($user in $currentTokens)
                    {
                        if($user.token -eq $token)
                        {
                            $user.enabled = $false
                            $user.history += [pscustomobject]@{event='disabled';by=$this.currentToken;date=$(get-date -format s)}
                            $user
                        }
                    }
                    $currentTokens | Export-Clixml $this.tokensPath -Force
                }else{
                    $return = $null
                }
                #$this.response = new-object adminResponse -ArgumentList ($return,$this.links,$inputs)
                $this.response = [adminResponse]::NEW($return,$this.links,$inputs)
                $this.adminCommand = 'updateUsers'
            }
            '/user/enable' {
                $inputs = @(

                    [pscustomobject] @{
                        name = 'username'
                        description = 'The username - to enable all associated tokens'
                        datatype = 'string'
                    },
                    [pscustomobject] @{
                        name = 'token'
                        description = 'Token to enable - not used if Username is specified'
                        datatype = 'string'
                    }
                )

                $this.makeLinks('/admin/user/enable',$null)

                $username = $this.requestParams.username
                $token = $this.requestParams.token
                if($username)
                {
                    $currentTokens = Import-Clixml $this.tokensPath
                    $return = foreach($user in $currentTokens)
                    {
                        if($user.username -eq $username)
                        {
                            $user.enabled = $true
                            $user.history += [pscustomobject]@{event='enabled';by=$this.currentToken;date=$(get-date -format s)}
                            $user
                        }
                    }
                    $currentTokens | Export-Clixml $this.tokensPath -Force
                }elseIf($token){
                    $currentTokens = Import-Clixml $this.tokensPath
                    $return = foreach($user in $currentTokens)
                    {
                        if($user.token -eq $token)
                        {
                            $user.enabled = $true
                            $user.history += [pscustomobject]@{event='enabled';by=$this.currentToken;date=$(get-date -format s)}
                            $user
                        }
                    }
                    $currentTokens | Export-Clixml $this.tokensPath -Force
                }else{
                    $return = $null
                }
                #$this.response = new-object adminResponse -ArgumentList ($return,$this.links,$inputs)
                $this.response = [adminResponse]::NEW($return,$this.links,$inputs)
                $this.adminCommand = 'updateUsers'
            }
            '/user/revokeAdmin' {
                $inputs = @(

                    [pscustomobject] @{
                        name = 'username'
                        description = 'The username - to revoke all associated tokens'
                        datatype = 'string'
                    },
                    [pscustomobject] @{
                        name = 'token'
                        description = 'Token to revoke Admin - not used if Username is specified'
                        datatype = 'string'
                    }
                )

                $this.makeLinks('/admin/user/revokeAdmin',$null)

                $username = $this.requestParams.username
                $token = $this.requestParams.token
                if($username)
                {
                    $currentTokens = Import-Clixml $this.tokensPath
                    $return = foreach($user in $currentTokens)
                    {
                        if($user.username -eq $username -and $user.isadmin -eq $true)
                        {
                            $user.isadmin = $false
                            $user.history += [pscustomobject]@{event='adminRevoked';by=$this.currentToken;date=$(get-date -format s)}
                            $user
                        }
                    }
                    $currentTokens | Export-Clixml $this.tokensPath -Force
                }elseIf($token){
                    $currentTokens = Import-Clixml $this.tokensPath
                    $return = foreach($user in $currentTokens)
                    {
                        if($user.token -eq $token -and $user.isadmin -eq $true)
                        {
                            $user.isadmin = $false
                            $user.history += [pscustomobject]@{event='adminRevoked';by=$this.currentToken;date=$(get-date -format s)}
                            $user
                        }
                    }
                    $currentTokens | Export-Clixml $this.tokensPath -Force
                }else{
                    $return = $null
                }
                #$this.response = new-object adminResponse -ArgumentList ($return,$this.links,$inputs)
                $this.response = [adminResponse]::NEW($return,$this.links,$inputs)
                $this.adminCommand = 'updateUsers'
            }
            '/user/grantAdmin' {
                $inputs = @(

                    [pscustomobject] @{
                        name = 'username'
                        description = 'The username - to elevate all associated tokens'
                        datatype = 'string'
                    },
                    [pscustomobject] @{
                        name = 'token'
                        description = 'Token to elevate - not used if Username is specified'
                        datatype = 'string'
                    }
                )

                $this.makeLinks('/admin/user/grantAdmin',$null)

                $username = $this.requestParams.username
                $token = $this.requestParams.token
                if($username)
                {
                    $currentTokens = Import-Clixml $this.tokensPath
                    $return = foreach($user in $currentTokens)
                    {
                        if($user.username -eq $username -and $user.isadmin -eq $false)
                        {
                            $user.isadmin = $true
                            $user.history += [pscustomobject]@{event='adminGranted';by=$this.currentToken;date=$(get-date -format s)}
                            $user
                        }
                    }
                    $currentTokens | Export-Clixml $this.tokensPath -Force
                }elseIf($token){
                    $currentTokens = Import-Clixml $this.tokensPath
                    $return = foreach($user in $currentTokens)
                    {
                        if($user.token -eq $token -and $user.isadmin -eq $false)
                        {
                            $user.isadmin = $true
                            $user.history += [pscustomobject]@{event='adminRevoked';by=$this.currentToken;date=$(get-date -format s)}
                            $user
                        }
                    }
                    $currentTokens | Export-Clixml $this.tokensPath -Force
                }else{
                    $return = $null
                }
                #$this.response = new-object adminResponse -ArgumentList ($return,$this.links,$inputs)
                $this.response = [adminResponse]::NEW($return,$this.links,$inputs)
                $this.adminCommand = 'updateUsers'
            }

            '/user/get' {
                $inputs = @(

                    [pscustomobject] @{
                        name = 'username'
                        description = 'The username to search for - accepts partial match'
                        datatype = 'string'
                    },
                    [pscustomobject] @{
                        name = 'token'
                        description = 'Token to search for - not used if Username is specified'
                        datatype = 'string'
                    },
                    [pscustomobject] @{
                        name = 'default'
                        description = 'If username/token not specified, all users will be retrieved'
                        datatype = 'none'
                    }
                )

                $this.makeLinks('/admin/user/get',$null)

                $username = $this.requestParams.username
                $token = $this.requestParams.token
                $currentTokens = Import-Clixml $this.tokensPath
                if($username)
                {
                    
                    $return = foreach($user in $currentTokens)
                    {
                        if($user.username -eq $username )
                        {
                            $user
                        }
                    }
                }elseIf($token){
                    $return = foreach($user in $currentTokens)
                    {
                        if($user.token -eq $token -and $user.isadmin -eq $false)
                        {
                            $user
                        }
                    }
                }else{
                    $return = $currentTokens
                }
                #$this.response = new-object adminResponse -ArgumentList ($return,$this.links,$inputs)
                $this.response = [adminResponse]::NEW($return,$this.links,$inputs)
            }

            '/user/'
            {
                $children = @(
                    '/new',
                    '/get',
                    '/grantAdmin',
                    '/revokeAdmin',
                    '/new',
                    '/disable',
                    '/enable'


                )
                $this.makeLinks('/admin/user/',$children)

                #$this.response = New-Object adminResponse -ArgumentList ($null,$this.links,$null)
                $this.response = [adminResponse]::NEW($null,$this.links,$null)
            }

        }
        

    }
}