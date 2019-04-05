
class listener
{

    [int]$port
    [string]$hostname
    [object]$httpListener
    [string]$apiPath
    [string]$serverPath
    [bool]$requireToken
    [int]$numberOfConnections = 0
    [int]$defaultCacheTime = 15
    [bool]$defaultCacheBehaviour = $true
    [bool]$defaultAuthBehaviour = $false
    hidden [string] $configPath
    hidden [string] $appPath 
    hidden [string] $tokensPath
    hidden [string] $logPath
    hidden [bool] $ok
    hidden [array] $currentTokens
    hidden [object] $user
    hidden [hashtable] $requestParams
    hidden [hashtable] $pageCache = @{}
    hidden [hashtable] $responseCache = @{}



    #CONSTRUCTORS DECONS AND INITS
    #LegacyConstructor
    #Uses defaults for cacheBehaviour etc
    #Required to leave it for compatibility reasons
    listener([int]$port,[string]$hostname,[string]$apiPath,[bool]$requireToken)
    {
        $this.verbose('====Listener Initialised: Legacy Constructor===')
        $this.verbose("Port:$Port;hostname:$hostname;apiPath:$apiPath;requireToken:$requireToken")
        $this.port = $port
        $this.hostname = $hostname
        $this.requireToken = $requireToken
        $this.serverPath = "http://$($this.hostname):$($this.port)/"
        $this.apiPath = $apiPath
        try{
            $winOS = [System.Boolean](Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop)
        }catch{
            $winOS = $false
        }
        if ($winOS)
        {
            $this.verbose('Server is Windows')
            $this.configPath = "$apiPath\config"
            $this.appPath = "$apiPath\api"
            $this.tokensPath = "$($this.configPath)\tokens.xml"
            $this.logPath = "$($this.configPath)\log.txt"
        }
        else
        {
            $this.verbose('Server is Not Windows')
            $this.configPath = "$apiPath/config"
            $this.appPath = "$apiPath/api"
            $this.tokensPath = "$($this.configPath)/tokens.xml"
            $this.logPath = "$($this.configPath)/log.txt"
        }

        if(Test-Path $apiPath)
        {            
            $this.initConfig()
            $this.verbose('starting listener Config')
            $this.configListener()
            $this.listen()
            
        }else{
            Write-Error 'There is a problem with your api Path'
            Write-Warning 'This Framework will not work with the current settings'
        }
        
        
    }

    #NewConstructor
    #Allows to set cacheBehaviour etc
    listener([int]$port,[string]$hostname,[string]$apiPath,[bool]$requireToken,[int]$defaultCacheTime,[bool]$defaultCacheBehaviour,[bool]$defaultAuthBehaviour)
    {
        $this.verbose('====Listener Initialised: New Constructor===')
        $this.verbose("Port:$Port;hostname:$hostname;apiPath:$apiPath;requireToken:$requireToken")
        $this.port = $port
        $this.hostname = $hostname
        $this.requireToken = $requireToken
        $this.serverPath = "http://$($this.hostname):$($this.port)/"
        $this.apiPath = $apiPath
        $this.defaultCacheTime = $defaultCacheTime
        $this.defaultCacheBehaviour = $defaultCacheBehaviour
        $this.defaultAuthBehaviour = $defaultAuthBehaviour
        try{
            $winOS = [System.Boolean](Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop)
        }catch{
            $winOS = $false
        }
        if ($winOS)
        {
            #windows
            $this.verbose('Server is Windows')
            $this.configPath = "$apiPath\config"
            $this.appPath = "$apiPath\api"
            $this.tokensPath = "$($this.configPath)\tokens.xml"
            $this.logPath = "$($this.configPath)\log.txt"
        }
        else
        {
            #Not windows
            $this.verbose('Server is Not Windows')
            $this.configPath = "$apiPath/config"
            $this.appPath = "$apiPath/api"
            $this.tokensPath = "$($this.configPath)/tokens.xml"
            $this.logPath = "$($this.configPath)/log.txt"
        }

        if(Test-Path $apiPath)
        {            
            $this.initConfig()
            $this.verbose('starting listener Config')
            $this.configListener()
            $this.listen()
            
        }else{
            Write-Error 'There is a problem with your api Path'
            Write-Warning 'This Framework will not work with the current settings'
        }
        
        
    }

    [void] initConfig()
    {
        $this.verbose('InitConfig')
        if(!(test-path $this.configPath))
        {
            
            try{
                New-Item -ItemType Directory -path $this.configPath
                New-Item -ItemType File -Path $this.logPath
                $this.ok = $true
                $this.verbose('config folder not found, created')

            }catch{
                Write-Error 'Unable to create configPath'
                $this.ok = $false
            }
        }else{
            $this.ok = $true
        }
        if(!(test-path $this.appPath))
        {
            $this.verbose('appPath folder not found, creating')
            try{
                New-Item -ItemType Directory -path $this.appPath
                $this.ok = $true
            }catch{
                Write-Error 'Unable to create appPath'
                $this.ok = $false
            }
        }else{
            $this.ok = $true
        }
        
        if(!(Test-path $this.tokensPath))
        {
            #We have no tokens yet
            #new-item -path $this.tokensPath
            
            $this.verbose("No tokens found, making one for the admin")
            #$newAdmin = new-object adminPage -ArgumentList @('/user/new',@{username='Administrator';isadmin=1},$this.tokensPath,'System')
            $newAdmin = [adminpage]::new('/user/new',@{username='Administrator';isadmin=1},$this.tokensPath,'System')
            
        }else{
            $this.verbose("Existing Tokens found, importing")
            $this.updateTokens()
        }

    }

    [void] configListener()
    {
        if($this.httpListener)
        {
            #Dispose the existing one
            #Need to make sure its closed

            if($this.httpListener.Listening -eq $true)
            {
                $this.verbose('Listener still listening, closing')
                $this.ForceCloseConnection()
            }
        }

        $this.verbose('Creating listener and basic config')
        try{
            $this.verbose('Substantiating listener')
            
            #$this.httpListener = $(new-object Net.HttpListener)
            $this.httpListener = [Net.HttpListener]::new()

        }catch{
            $this.verbose('Unable to substantate listener object')
            write-error 'Unable to substantiate listener object'
            
        }
        try{
            $this.verbose('Configuring listener')
            
            $this.httpListener.Prefixes.add($this.serverPath)
            $this.httpListener.AuthenticationSchemes = 'Anonymous'
            #$this.httpListener.AuthenticationSchemes = 'Basic'

            $this.verbose('Listener Config Finished')
        }catch{
            write-error 'Error configuring listener'
            $this.ForceCloseConnection()


        }

        try{
                
            $this.verbose('Starting the listener')
            $this.httpListener.Start()

        }Catch{
            write-error 'Unable to start listener'

            $this.ForceCloseConnection()
        }

    }

    [void] closeConnection()
    {
        $this.verbose('Resetting connection')
        $this.user = $null
        $this.requestParams = @{}

    }

    [void] ForceCloseConnection()
    {
        $this.verbose('Closing the connection')
        #Try and clear the params
        $this.user = $null
        $this.requestParams = @{}
        try{
            $this.httpListener.stop()
            $this.httpListener.Close()
        }catch{
            write-warning 'I was unable to stop the listener... HES A MAD-MAN'
        }

    }

   

    #LISTENER MAIN
    

    [void] listen()
    {
        #Try and clear the params
        #Essential to start from clean slate
        $this.requestParams = @{}
        $this.user = $null
        if($this.ok -eq $true)
        {
           
            try{
                
                #$this.verbose('Handling any requests')
                $this.getRequest()
            


            }catch{
                write-error 'unable to handle request'
              
                $this.ForceCloseConnection()
            }
        }else{
            $this.ForceCloseConnection()
            $this.verbose('Listener not started')
            Write-Warning 'The listener is not started, ok not true'
        }
    }


    #PARAM HELPERS

    [void] getQueryData($queryString)
    {
        $this.verbose('Getting GET Params')
        $this.requestParams = @{}
        foreach($get in $queryString)
        {
            $this.requestParams."$get" = $queryString[$get]
            

        }
        

    }

    [void] getPostData($inputstream,$ContentEncoding)
    {
        $this.verbose('Getting POST Params')
        try{
            ##$StreamReader = New-Object IO.StreamReader($inputstream,$ContentEncoding)
            $this.verbose('Creating Stream Reader')
            $StreamReader = [IO.StreamReader]::new($inputstream,$ContentEncoding)
            $this.verbose('Reading Stream')
            $read = $StreamReader.ReadToEnd()
            try{
                $readJson = $read|ConvertFrom-Json
                $this.verbose('Json POST data found')
                $properties = $($readJson | get-member -membertype NoteProperty).Name
                foreach($property in $properties)
                {
                    $this.verbose("Creating Property: $property")
                    $this.requestParams."$property" = $readJson."$property"
                }

            }catch{


                $this.verbose('Fallback to String POST data - using split to extract Params')

                foreach ($Post in $($read.Split('&')))
                {
                    $PostContent = $Post.Split("=")
                    $PostName = $PostContent[0]
                    $PostValue = $($PostContent[1..$($PostContent.count)] -join '=')
                    if($PostName.EndsWith("[]"))
                    {
                        $PostName = $PostName.Substring(0,$PostName.Length-2)
                    }
                    $this.verbose("Creating Property: $PostName")
                    $this.requestParams."$PostName" = $PostValue
                }

            }

        }catch{
            
            $this.verbose('Unable to read stream')
        }


    }


    #REQUEST HELPER
    #Probably the biggest function


    [void] getRequest()
    {
        
        $this.verbose('Awaiting Request')
        $context = $this.httpListener.GetContext()
        $this.numberOfConnections++
        $this.verbose("`n====START====`n`tConnection $($this.numberOfConnections)")
        $global:lastContectCheck = $context
        $request = $context.Request
        $identity = $context.User.Identity
        $r = $null
        
        #write-verbose "`n==`n$($request | format-list * | Out-String)`n==`n"
        if($request.HttpMethod -eq 'Post')
        {
            $this.getPostData($request.InputStream,$request.ContentEncoding)

        }else{
            $this.getQueryData($request.QueryString)
        }     
        
        $token = $request.headers['x-api-token']
        #$this.verbose("Token Obj : $($token)")
        
        $response = $context.Response
        $Response.Headers.Add('Accept-Encoding','gzip')
        $Response.Headers.Add('Server','psRapid')
        #Since this is an API, deal with CORS headers

        $Response.Headers.Add('Access-Control-Allow-Origin','*')
        
        $response.headers.add('Access-Control-Allow-Methods','GET,POST,HEAD,OPTIONS')

        $this.user = $this.getUser($token)
        $page = $request.RawUrl.Split('?')[0]
        $this.verbose("REQUEST DETAILS:`n`tRequested Page: $page`n`tToken: $($token)`n`tRefer: $($request.UrlReferrer)`n`tUserHostAddress: $($request.UserHostAddress)`n`tRemoteEndPoint: $($request.RemoteEndPoint)`n`tIsLocal:$($request.IsLocal)`n")
        $this.verbose("PARAMS: `n$($this.requestParams|format-list|out-string)`n")
        #ADMIN PAGE CHECK AND USER AUTH
        if($page -like '/admin*' -and $this.user.isAdmin -eq $true -and $this.user.enabled -eq $true)
        {
            $this.verbose("`n====ADMIN PAGE====`n`Token: $($this.user.token)")
            try{
                $response.StatusCode = '200'
                #$adminPage = new-object adminPage -ArgumentList @($($page -replace '/admin',''),$this.requestParams,$this.tokensPath,$this.user.token)
                $adminPage = [adminPage]::New($($page -replace '/admin',''),$this.requestParams,$this.tokensPath,$this.user.token)
                $r = $adminPage.response.json()
                if($adminPage.adminCommand -eq 'stop')
                {
                    $this.verbose('Request to stop server')
                    $this.ok = $false
                }
                if($adminPage.adminCommand -eq 'clearCache')
                {
                    $this.verbose('Request to clear cache')
                    $this.pageCache = @{}
                    $this.responseCache = @{}
                }
                if($adminPage.adminCommand -eq 'updateUsers')
                {
                    $this.verbose('Request to update users')
                    $this.updateTokens()
                }
                
            }catch{
                
                #$this.verbose('Error with Admin Page Creation')
                write-error 'Error with admin page creation'
                $adminPage = $null
                $response.StatusCode = 418
                $r = 'Im a Teapot - Error with admin page creation'

            }

        #GENERAL PAGE CHECK AND USER AUTH
        }elseif((($this.user.enabled -eq $true)-and($this.requireToken -eq $true))-or($this.requireToken -eq $false)){
            try{
                $authorized = $true
                #$this.verbose('Normal Page Request')
                $ext = if($page[-1] -eq '/'){''}else{'.ps1'}
                $requestedPagePath = "$($this.appPath)$($page.replace('/','\'))$($ext)"
                if(Test-Path $requestedPagePath){
                    $this.verbose("Path Valid - $requestedPagePath")

                }else{
                    $this.verbose("Path invalid, setting to default - $requestedPagePath")
                    $requestedPagePath = $this.appPath
                }
                $response.StatusCode = '200'
                $p = $this.pageCache."$requestedPagePath"
                if(!$p)
                {
                    #$this.verbose('Retrieving Page Details')
                    #$p = new-object page -ArgumentList ($requestedPagePath,$page)
                    #The below method works in linux, the above only works in windows, use the below for compatibility reasons
                    $p = [page]::new($requestedPagePath,$page,$this.defaultCacheTime,$this.defaultCacheBehaviour,$this.defaultAuthBehaviour)
                    $this.verbose('Page Retrieved - Saving Page to Cache')
                    $this.pageCache."$requestedPagePath" = $p
                    
                    #$this.verbose("Current Pages Cached: `n`n $($this.pageCache.keys)")
                }else{
                    $this.verbose('Page retrieved from Cache')
                }

                #This is where we check the user is authorised for the page network access restrictions and if auth is required
                
                if($p.ipRanges)
                {
                    #Whats this users IP Address as a decimal
                    #First need to handle if the request is local, maybe just make it loopback
                    #Then if its not, we need to separate the IP from the Port
                    #Then when we have an IP address, need to convert it to decimal for better maths
                    $authorized = $false
                    $ipAddress = 'a.b.c.d' #Need something because classes are so strict
                    $this.verbose('Need to confirm IP Range')
                    if($request.IsLocal -eq $true)
                    {
                        $ipAddress = '127.0.0.1'
                    }else{
                        #[::1]:59271
                        #10.123.42.27:80
                        $regex = '[^0-9.:]+'
                        $regexIPv4 = '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}'
                        $ipAndPortOnly = $request.RemoteEndPoint -replace $regex
                        $ipTest = $($ipAndPortOnly.substring(0,$($ipAndPortOnly.indexOf(':')))).trim()
                        If($ipTest -match $regexIPv4 ){
                           #IPv4 looks ok 
                           $ipAddress = $ipTest
                        }else{
                            #Not an IP so throw unauth
                            $this.verbose('Not an IPAddress')
                            $authorized = $false
                        }
                    }

                    $this.verbose("Got this IP: $ipAddress")

                    try{
                        $ipCompare = [ipAssist]::convertIpToInt($ipAddress)
                        $this.verbose("Using IP Int: $ipCompare")
                        foreach($range in $($p.ipRanges))
                        {
                            if($ipCompare -ge $range.min -and $ipCompare -le $range.max)
                            {
                                $this.verbose("IP in range block, should authorize`n`tRange: $($range.first) <-$ipAddress-> $($range.last)`n`tRange: $($range.min) <-$ipCompare-> $($range.max)")
                                $authorized = $true
                            }else{
                                $this.verbose("IP not in range block`n`tRange: $($range.first) <-$ipAddress-> $($range.last)`n`tRange: $($range.min) <-$ipCompare-> $($range.max)")
                            }
                        }
                    }catch{
                        $authorized = $false
                    }
                }else{
                    $this.verbose('Not checking IP Range')
                }

                if($p.auth -eq $true)
                {
                    $authorized = $false
                    if($this.user.enabled)
                    {
                        $this.verbose('User is enabled')
                        $authorized = $true
                    }
                }       

                if($authorized -eq $true)
                {
                    $this.verbose('Access is authorized')
                    #Ensure script is null
                    $script = $null
                    
                    #Check for headers hashable param in the page inputs
                    $headersInput = $p.inputs | Where-object {$_.name -eq 'headers' -and $_.datatype -eq 'hashtable'}
                    #$this.verbose("$($p.inputs|Format-Table|out-string)")
                    #This allows passing of headers from the request to the scriptblock if required
                    #Should mostly not need this
                    $this.verbose("HeadersInput: `t $(if($headersInput){$true}else{$false})")
                    if($headersInput)
                    {
                        $this.verbose("HeadersFound:`n$($headersInput|Format-Table|out-string)")
                        
                        $headerValuesHash = @{}
                        foreach($item in $context.request.Headers)
                        {
                            $headerValuesHash."$item" = $context.Request.Headers["$item"]
                        }
                        
                        $headerValuesHash.UserHostAddress = $context.request.UserHostAddress
                        $headerValuesHash.UserHostName = $context.request.UserHostName
                        $headerValuesHash.UrlReferrer = $context.request.UrlReferrer
                        $headerValuesHash.IsSecureConnection = $context.request.IsSecureConnection
                        $headerValuesHash.IsLocal = $context.request.IsLocal
                        $headerValuesHash.Cookies = $context.request.Cookies
                        $headerValuesHash.RemoteEndpoint = $context.request.RemoteEndPoint
                        
                        $this.requestParams.Headers = $headerValuesHash
                        #$this.verbose("HeadersPassed: $($headerValuesHash |Format-List|Out-String)")
                    }

                    #$this.verbose('+--=finished param building=--+')
                    #If we have a file, we need to execute it
                    #Check we have a response in the responseCache

                    
                    
                    if($p.cache -eq $true)
                    {
                        $this.verbose('Checking for cached result')
                        #Work out a cacheKey
                        #Should incorporate the page plus the params somehow
                        
                        #$cacheKey = "$($page)::$($($($this.requestParams.keys|sort-object) -join '').tolower())::$($($($this.requestParams.values|sort-object) -join '').tolower())"

                        $cachekeyParams = [array]$($($($this.requestParams.keys)|sort-object)|ForEach-Object{"$($_)$($this.requestParams.$_)"}) -join ''
                        
                        $cacheKey = "$($page)::$cachekeyParams"


                        $this.verbose("Using CacheKey:$cacheKey")
                        if($this.responseCache."$cacheKey")
                        {
                            $this.verbose('responseCache found for object, checking expiry')
                            
                            if($this.responseCache."$cacheKey".expires -gt $(get-date))
                            {
                                $this.verbose("Cache Valid until:  $($this.responseCache."$cacheKey".expires)")
                                $this.verbose('responseCache looks valid, returning cached result')
                                $responsepage = $this.responseCache."$cacheKey".response
                                $responsepage.fromCache()
                                $r = $responsepage.json()
                            }else{
                                $this.verbose("Cache Expired:  $($this.responseCache."$cacheKey".expires)")
                            }
                        }

                        if($r -eq $null)
                        {
                            $this.verbose('No valid cache found. Creating new response')
                            #No response json, make a new response
                            #Add it to the cache as well
                            try{
                                #$script = new-object script -ArgumentList @($p.filepath,$this.requestParams)
                                if($p.isFile -eq $true)
                                {
                                    $script = [script]::new($($p.filepath),$this.requestParams)
                                }
                                
                                $responsepage = [pageResponse]::new($p,$script)
                                $this.responseCache."$cacheKey" = [cacheObject]::New($responsepage,$p.cachetime)
                                $r = $responsepage.json()
                                $this.verbose('Script execution ok')
                            }catch{
                                $this.verbose('Bad script execution')
                                $r = 'Im a Teapot - Error with page Response'
                                $response.StatusCode = 418
                            }

                        }
                    }else{
                        $this.verbose('Cache for page set to false')
                        try{
                            #$script = new-object script -ArgumentList @($p.filepath,$this.requestParams)
                            if($p.isFile -eq $true)
                            {
                                $script = [script]::new($($p.filepath),$this.requestParams)
                            }
                            $responsepage = [pageResponse]::new($p,$script)
                            $r = $responsepage.json()
                            $this.verbose('Script execution ok')
                        }catch{
                            $this.verbose('Bad script execution')
                            $r = 'Im a Teapot - Error with page Response'
                            $response.StatusCode = 418
                        }
                    }
                }else{
                    #Return unauthorized
                    $this.verbose('User is unauthorized')
                    $response.StatusCode = '401'
                    $r = 'Access is denied - invalid token'

                }
            }catch{
                $this.verbose('Error with Page Creation')
                write-error 'Error with page creation'
                $response.StatusCode = 418
                $r = 'Im a Teapot - Error with page creation'
            }
        #ACCESS DENIED
        }else{
            $this.verbose('Creating a deny response')
            $response.StatusCode = '401'
            $r = 'Access is denied - invalid token'
        }
        
        $this.user = $null
        #$this.verbose('Encoding Response')
        #$this.verbose("RETURN OBJECT: `n$r`n`n")

        if($r)
        {
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($r)
            $response.ContentLength64 = $buffer.Length
        }else{
            $buffer=''
            $response.ContentLength64 = 0
        }
        
        $this.verbose('Sending response')
        $output = $response.OutputStream
        $output.Write($buffer,0,$response.ContentLength64)
        $output.Close()

        $this.closeConnection()

        $this.verbose("This connection is finished`n====END====")
        $this.listen()

    }

    #LOGGING HELPER

    [void] verbose([string]$message)
    {
        #Simple verbose helper to include the date
        $logAs = "[$(get-date -Format s)]`t $message"
        Write-Verbose $logAs
        if(!$this.logPath)
        {
            write-warning 'Not Logged to file'
        }else{
            try{
                $logAs|Out-File $this.logPath -Append -NoClobber -Force
                $xLogFile = $this.logPath
                if($xLogFile.length -gt 20mb)
                {
                    $newname = "$($xLogFile.basename)$(get-date -format yyyyMMdd.hhmmss).txt"
                    rename-item $this.logPath -NewName $newname
                }
            }catch{
                write-warning 'Error logging to file'
            }
        }
    }

    #User functions
    
    [void] updateTokens()
    {
        $this.verbose('Importing tokens')
        $this.currentTokens = Import-Clixml $this.tokensPath
    }

    
    [object] getUser($token)
    {
        
        $this.verbose("Checking Valid Token: $token")
        $findUser = $this.currentTokens|Where-Object {$_.token -eq $token}
        if(!$findUser)
        {
            $this.verbose('Token not found, refreshing token list')
            $this.updateTokens()
            $findUser = $this.currentTokens|Where-Object {$_.token -eq $token}
        }
        if($findUser -and $findUser.enabled -eq $true)
        {
            $this.verbose("Token valid")
            #$this.verbose("`n$($findUser|format-list|out-string)")
            return $findUser
        }else{
            $this.verbose("Token not valid")
            return $null
        }
    }

}