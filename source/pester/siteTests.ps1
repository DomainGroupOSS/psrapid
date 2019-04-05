Param(
    $moduleVersion,
    $modulePath,
    $moduleName
)

$testSite = 'testSite'
$testFolder = "$($env:temp)\$testSite"
if(test-path $testFolder)
{
    remove-item -Force -Path $testFolder -Confirm:$false -Recurse |out-null
}


new-item -ItemType Directory -Path $testFolder -Force |out-null
#Use this to ensure we get rid of any special characters, concatinating etc
#Because the environment variable makes the temp folder cmd prompt safe, but PS doesnt need that
$testPath = "$($(get-item $testFolder).fullname)"
set-location $testPath

describe 'Check Current Folder' {
    context 'Check Variables' {
        it 'Should have a proper path string in the testPath var' {
            $testPath | should -not -be $null
        }
        it 'Should have a proper path string in the testFolder var' {
            $testFolder | should -not -be $null
        }
    }
    context 'Check Exists' {
        it "should be $testPath" {
            $(get-location).path | Should -Be $testPath
        }
        it 'Should be Empty' {
            $(get-childitem $testPath) |Should -be $null
        }
    }
}

$txtTest1 = @'
<#
    .SYNOPSIS
        Return a pscustom object
        
    .DESCRIPTION
        Example
        
    .PARAMETER textA
        Start Text

    .PARAMETER textB
        End Text
    
#>
[CmdletBinding()]
param(
    [string]$textA,
    [string]$textB
)


if($textA -is [string] -and $textB -is [string])
{
    [pscustomobject] @{
        inputA = $textA
        inputB = $textB
        output = "$textA $textB"
        method = 'concatenate'
    }
}

'@

$txtTest2 = @'
<#
    .SYNOPSIS
        Return a pscustom object
        
    .DESCRIPTION
        Example
        
    .PARAMETER text
        text to manipulate
    
#>
[CmdletBinding()]
param(
    [string]$text
)


if($text -is [string])
{
    [pscustomobject] @{
        input = $text
        output = $text.ToLower()
        method = 'lowercase'
    }
}

'@

$mathTest1 = @'
<#
    .SYNOPSIS
        Add two numbers together
        
    .DESCRIPTION
        Example
        
    .PARAMETER x
        The first number to add

    .PARAMETER y
        The second number to add
    
#>
[CmdletBinding()]
param(
    [int]$x,
    [int]$y
)

if(($x -is [int])-and(($y -is [int])))
{
    [pscustomobject] @{
        x = $x
        y = $y
        result = $x+$y
        method = 'add'
    }
}
'@

$mathTest2 = @'
<#
    .SYNOPSIS
        Add two numbers together
        
    .DESCRIPTION
        Example
        
    .PARAMETER x
        The multiplicand

    .PARAMETER y
        The multiplier
    
#>
[CmdletBinding()]
param(
    [int]$x,
    [int]$y
)

if(($x -is [int])-and(($y -is [int])))
{
    [pscustomobject] @{
        x = $x
        y = $y
        result = $x*$y
        method = 'multiply'
    }
}
'@

$headerTest = @'
<#
    .SYNOPSIS
        Add two numbers together
        
    .DESCRIPTION
        Example
        
    .PARAMETER hashtable
        A hashtable with headers
        Used to make sure headers can be read by functions if desired
    
#>
[CmdletBinding()]
param(
    [hashtable]$headers
)

$testHeader = $headers.test
[pscustomobject] @{
    allHeaders = $headers
    result = $testHeader
    method = 'headerCheck'
}
'@

$pageControlTest1 = @'
<#
    .SYNOPSIS
        
        
    .DESCRIPTION
        Should only cache for 1 minute
        This is tricky to test with Pester, 
        but will leave it in for manual testing
        Since we are not telling the client its cached
        Actually, maybe we can tell the server its cached
        
    .PARAMETER string
        A simple string
    
#>

[PageControl(
    cacheMins = 1,
    cache = $true

)]


[CmdletBinding()]

param(
    [string]$string
)

$testHeader = $headers.test
[pscustomobject] @{
    returnString = $string
}
'@

$pageControlTest2 = @'
<#
    .SYNOPSIS
        
        
    .DESCRIPTION
        Example
        
    .PARAMETER string
        A simple string
    
#>

[PageControl(
    cache = $false,
    networkRange = ('127.0.0.1/32','10.0.0.0/8'),
    tokenRequired = $true
)]


[CmdletBinding()]

param(
    [string]$string
)

$testHeader = $headers.test
[pscustomobject] @{
    returnString = $string
}
'@


$pageControlTest3 = @'
<#
    .SYNOPSIS
        
        
    .DESCRIPTION
        Example
        
    .PARAMETER string
        A simple string
    
#>

[PageControl(
    cache = $true,
    networkRange = ('10.0.0.0/8')
)]


[CmdletBinding()]

param(
    [string]$string
)

$testHeader = $headers.test
[pscustomobject] @{
    returnString = $string
}
'@



new-item -path "$testPath\api" -ItemType Directory |out-null
new-item -Path "$testPath\api\math" -ItemType Directory |out-null
new-item -Path "$testPath\api\txt" -ItemType Directory |out-null
new-item -Path "$testPath\api\pgcontrol" -ItemType Directory |out-null

$txtTest1|out-file -FilePath "$testPath\api\txt\concatinate.ps1"
$txtTest2|out-file -FilePath "$testPath\api\txt\lowercase.ps1"
$mathTest1|out-file -FilePath "$testPath\api\math\add.ps1"
$mathTest2|out-file -FilePath "$testPath\api\math\multiply.ps1"
$headerTest|out-file -FilePath "$testPath\api\headerTest.ps1"
$pageControlTest1|out-file -FilePath "$testPath\api\pgcontrol\pageControl1.ps1"
$pageControlTest2|out-file -FilePath "$testPath\api\pgcontrol\pageControl2.ps1"
$pageControlTest3|out-file -FilePath "$testPath\api\pgcontrol\pageControl3.ps1"



describe 'class tests' {
    
    context 'Can Create Page class with folder using legacy constructor' {
        $testPage = [page]::new("$testPath\api\txt","test/api/txt",15,$true,$false)
        it 'should have created a page with folder details' {
            $testPage | should -not -be $null
            $testPage.isFile | should -be $false

        }
        it 'Should have a valid filepath' {
            $testpage.filepath |should -not -be $null
        }
        it 'should be a hashtable' {
            $testPage.links | should -not -be $null
            $testPage.links.getType().name | should -Be 'Hashtable'
        }
        it 'Should have values in the hashtable' {
            $testPage.links.keys.count |Should -not -be $null
            $testPage.links.keys.count |Should -BeGreaterThan 0
        }

    }


    $testPage = [page]::new("$testPath\api\txt\concatinate.ps1","test/api/txt/concatinate",15,$true,$false)
    context 'Can Create Page class with file path and new constructor' {
        it 'should have created a page with file details' {
            $testPage | should -not -be $null
            $testPage.isFile | should -be $true

        }
        it 'Should have a valid filepath' {
            $testpage.filepath |should -not -be $null
        }
        it 'should be a hashtable' {
            $testPage.links | should -not -be $null
            $testPage.links.getType().name | should -Be 'Hashtable'
        }
        it 'Should have values in the hashtable' {
            $testPage.links.keys.count |Should -not -be $null
            $testPage.links.keys.count |Should -BeGreaterThan 0
        }
        it 'Should have values in the hashtable' {
            $testPage.links.keys.count |Should -not -be $null
            $testPage.links.keys.count |Should -BeGreaterThan 0
        }
        it 'Should have inputs returned' {
            $testpage.inputs.count |should -not -be $null
        }
        it 'Should have correct Name' {
            $testpage.inputs[0].name | should -be 'textA'
        }
        it 'Should have the expected datatype' {
            $testpage.inputs[0].datatype |should -be 'string'
        }

    }
    $testParams = @{textA = 'The first part';textB = 'the second part'}
    $testScript = [script]::New($testPage.filepath,$testParams)
    context 'Can create a Script class' {
        it 'Should have created the object' {
            $testScript | Should -not -be $null
        }
        it 'Should have created the correct class' {
            $testScript.getType().name | Should -be 'script'
        }
        it 'Should have some results' {
            $testScript.results |should -not -be $Null
        }
        it 'Should have the correct result method' {
            $testScript.results.method |should -be 'concatenate'
        }
        it 'Should have the correct result output' {
            $testScript.results.output |should -be 'The first part the second part'
        }
    }

    context 'Can create pageResponse class' {
        $testResponse = [pageResponse]::New($testPage,$testScript)
        it 'Should have created the object' {
            $testResponse | Should -not -be $null
        }
        it 'Should have created the correct class' {
            $testResponse.getType().name | Should -be 'pageResponse'
            $testResponse.getType().BaseType | Should -be 'response'
        }
        it 'Should have the correct ServerType' {
            $testResponse.server |Should -be 'psRapid'
            
        }
        it 'Should have the right response' {
            $testResponse.itemCount| Should -BeGreaterOrEqual 1
            $testResponse.items |Should -be $testScript.results
        }
        it 'Should have the right inputs' {
            $testResponse.inputs |Should -be $testpage.inputs
        }
        it 'Should have the right links' {
            $testResponse.links |Should -be $testpage.links
        }
    }
}

describe 'Check NSSM is present' {
    $nssm = get-item -Path "$modulePath\bin\nssm.exe"
    it 'Should be an exe item' {
        $nssm | Should -not -be $null
        $nssm.Extension |should -be '.exe'
    }
}

#Check the listener
$port = 9889
$startup = @"
import-module '$modulePath\psRapid.psd1'
`$port = $port
`$apiHostname = 'localhost'
`$requireToken = `$false
`$apiPath = '$testPath'
[listener]::NEW(`$port,`$apiHostname,`$apiPath,`$requireToken)
"@

$scriptblock = [scriptblock]::Create($startup)
describe 'Scriptblock for Listener' {
    it 'Should be a valid scriptblock' {
        $scriptblock.GetType().name | should -be 'ScriptBlock'
    }
}

$job = start-job -ScriptBlock $scriptblock
start-sleep -Seconds 5 |Out-Null

#get the token
describe 'Check the listener' {
    context 'Check the job' {
        it 'Should be in a running state' {
            $(get-job $job.id).State |should -be 'Running'
        }
        it 'Should be running locally' {
            $(get-job $job.id).Location |should -be 'localhost'
        }
        
    }
    $tokenPath = "$testPath\config\tokens.xml"
    $tokens = Import-Clixml $tokenPath -ErrorAction Ignore
    $adminToken = $tokens|Where-Object{$_.username -eq 'Administrator'}
    $logPath = "$testPath\config\log.txt"
    context 'Config should have been created' {
        it 'Should have created the token file' {
            $(test-path $tokenPath) | should -be $true
        }
        it 'Should have a log file' {
            $(test-path $logpath) | should -be $true
        }
    }
    context 'Admin token created' {
        it 'Should not be null' {
            $adminToken| Should -not -be $null
        }
        it 'Should be an admin' {
            $adminToken.isAdmin |Should -be $true
        }
        it 'Should be enabled' {
            $adminToken.enabled|should -be $true
        }
        it 'Should have a valid token' {
            $adminToken.token |should -not -be $null
            $admintoken.token.length |should -be 36
            $adminToken.token[8] |should -be '-'
        }
    }
    $tokenHeader = @{'x-api-token' = $adminToken.token}
    context 'Admin token should be valid' {
        it 'Should be a hashtable' {
            $tokenHeader.GetType().name |should -be 'hashtable'
        }
        it 'Should contain x-api-token' {
            $tokenHeader.'x-api-token' |should -not -be $null
        }
        it 'Should match the token in the config' {
            $tokenHeader.'x-api-token' | should -be $adminToken.token
        }
    }
    context 'Rest method should work' {
        $restRequest = invoke-restmethod -uri "http://localhost:$port"
        it 'Should have a succesful rest call' {
            $restRequest|should -not -be $null
        }
        it 'Should have correct server type' {
            $restRequest.server |should -Contain 'psRapid'
        }
        it 'Should have zero item count' {
            $restRequest.itemCount |should -be 0
        }
    }
    context 'Check test API with GET' {
        $restRequest = invoke-restMethod -uri "http://localhost:$port/math/add?x=1&y=2"
        it 'Should have links' {
            $restRequest.links.gettype().name|Should -be 'PSCustomObject'
        }
        it 'Should have the correct inputs' {
            $restRequest.Inputs.getType().basetype |should -be 'Array'
        }
        it 'should have the right results' {
            $restRequest.items.method |Should -be 'add'
            $restRequest.items.result | Should -be 3
        }
        it 'should have cachedResponse eq false' {
            $restRequest.cachedResponse |Should -be $false
        }

    }
    context 'Check the default cache response' {
        $restRequest = invoke-restMethod -uri "http://localhost:$port/math/add?y=2&x=1"
        it 'Should have links' {
            $restRequest.links.gettype().name|Should -be 'PSCustomObject'
        }
        it 'Should have the correct inputs' {
            $restRequest.Inputs.getType().basetype |should -be 'Array'
        }
        it 'should have the right results' {
            $restRequest.items.method |Should -be 'add'
            $restRequest.items.result | Should -be 3
        }
        it 'should have cachedResponse eq true' {
            $restRequest.items.method |Should -be $true
        }

    }
    context 'Check test API with POST' {
        $restRequest =  Invoke-RestMethod -Uri "http://localhost:$port/math/add" -body $(@{x=1;y=2}|convertTo-json) -Method post
        it 'Should have links' {
            $restRequest.links.gettype().name|Should -be 'PSCustomObject'
        }
        it 'Should have the right "this" reference link' {
            $restRequest.links.this |should -be '/math/add'
        }
        it 'Should have the right parent reference link' {
            $restRequest.links.parent |should -be '/math'
        }
        it 'Should have the correct inputs type' {
            $restRequest.Inputs.getType().basetype |should -be 'Array'
        }
        it 'Should have the right input fields' {
            $restRequest.inputs[0].name | Should -be 'x'
            $restRequest.inputs[0].datatype | Should -be 'Int32'
        }
        it 'should have the right results' {
            $restRequest.items.method |Should -be 'add'
            $restRequest.items.result | Should -be 3
        }

    }
    context 'Check the Headers Test Page' {
        $headers = @{test='This is a test'}
        $restRequest =  Invoke-RestMethod -Uri "http://localhost:$port/headerTest" -Headers $headers
        it 'Should have a succesful rest call' {
            $restRequest|should -not -be $null
        }

        it 'Should have a returned some inputs' {
            $restRequest.inputs.name |should -be 'headers'
        }

        it 'Should have a returned some items' {
            $restRequest.items.count |should -not -be $null
        }

        it 'should have the right results' {
            #$restRequest.items.method |Should -be 'headerCheck'
            $restRequest.items.result | Should -be 'This is a test'
        }

    }

    context 'Check the admin page links' {
        $restRequest = Invoke-RestMethod -Uri "http://localhost:$port/admin" -Headers $tokenHeader
        it 'Should have the right this link' {
            $restRequest.links.this |Should -be '/admin/'
        }
        it 'Should have the stop child link' {
            $restRequest.links.children|should -Contain '/stop'
        }
        it 'Should have the correct user child links ' {
            $restRequest.links.children | Should -contain '/user/'
            $restRequest.links.children | Should -contain '/user/new'
            $restRequest.links.children | Should -contain '/user/disable'
            $restRequest.links.children | Should -contain '/user/get'
            $restRequest.links.children | Should -contain '/user/revokeAdmin'
            $restRequest.links.children | Should -contain '/user/grantAdmin'
        }
        it 'Should have the clearCache method link' {
            $restRequest.links.children | Should -contain '/clearCache'
        }
    }
    context 'Create a new user' {
        $restRequest = Invoke-RestMethod -Uri "http://localhost:$port/admin/user/new?username=secondUser&isadmin=0" -Headers $tokenHeader
        it 'should have created a new user' {
            $restRequest.items.username |Should -be 'secondUser'
        }
        it 'Should be enabled' {
            $restRequest.items.enabled |Should -be $true
        }
        it 'Should not be an admin' {
            $restRequest.items.isadmin |should -be $false
        }
    }
    context 'Change user to admin' {
        $restRequest = Invoke-RestMethod -Uri "http://localhost:$port/admin/user/grantadmin?username=secondUser" -Headers $tokenHeader
        it 'should have created a new user' {
            $restRequest.items.username |Should -be 'secondUser'
        }
        it 'Should be enabled' {
            $restRequest.items.enabled |Should -be $true
        }
        it 'Should be an admin' {
            $restRequest.items.isadmin |should -be $true
        }
    }
    context 'Revoke user from admin' {
        $restRequest = Invoke-RestMethod -Uri "http://localhost:$port/admin/user/revokeadmin?username=secondUser" -Headers $tokenHeader
        it 'should have created a new user' {
            $restRequest.items.username |Should -be 'secondUser'
        }
        it 'Should be enabled' {
            $restRequest.items.enabled |Should -be $true
        }
        it 'Should not be an admin' {
            $restRequest.items.isadmin |should -be $false
        }
    }
    context 'Disable user' {
        $restRequest = Invoke-RestMethod -Uri "http://localhost:$port/admin/user/disable?username=secondUser" -Headers $tokenHeader
        it 'should have created a new user' {
            $restRequest.items.username |Should -be 'secondUser'
        }
        it 'Should be disabled' {
            $restRequest.items.enabled |Should -be $false
        }
        it 'Should not be an admin' {
            $restRequest.items.isadmin |should -be $false
        }
    }
    context 'Page Control Attributes 1 - no cache'{
        $restRequest = Invoke-RestMethod -Uri "http://localhost:$port/pgcontrol/pageControl1?string=aString"
        it 'Should have a succesful rest call' {
            $restRequest|should -not -be $null
        }

        it 'Should have a returned some inputs' {
            $restRequest.inputs.name |should -be 'string'
        }

        it 'Should have a returned some items' {
            $restRequest.items.count |should -not -be $null
        }

        it 'should have the right results' {
            #$restRequest.items.method |Should -be 'headerCheck'
            $restRequest.items.returnString | Should -be 'aString'
        }
        it 'should have cachedResponse eq false' {
            $restRequest.cachedResponse |Should -be $false
        }
    }
    context 'Page Control Attributes 2 - should cache'{
        $restRequest = Invoke-RestMethod -Uri "http://localhost:$port/pgcontrol/pageControl1?string=aString"
        it 'Should have a succesful rest call' {
            $restRequest|should -not -be $null
        }

        it 'Should have a returned some inputs' {
            $restRequest.inputs.name |should -be 'string'
        }

        it 'Should have a returned some items' {
            $restRequest.items.count |should -not -be $null
        }

        it 'should have the right results' {
            #$restRequest.items.method |Should -be 'headerCheck'
            $restRequest.items.returnString | Should -be 'aString'
        }
        it 'should have cachedResponse eq true' {
            $restRequest.cachedResponse |Should -be $true
        }
    }
    context 'Page Control Attributes 3 - should disallow as no token but correct IP'{
        $restRequest = $null
        it 'Should not have a current restRequest' {
            $restRequest|should -be $null
        }
        try{
            $restRequest = Invoke-RestMethod -Uri "http://localhost:$port/pgcontrol/pageControl2?string=aString"
        }catch{
            $responseCode = $_.Exception.Response.StatusCode.Value__
        }

        it 'Should still have no current restRequest' {
            $restRequest|should -be $null
        }

        it 'Should have a responseCode' {
            $responseCode|should -not -be $null
        }

        it 'Should have responsecode of 401 - Access Denied' {
            $responseCode|should -be 401
        }
    }

    context 'Page Control Attributes 3 - should allow with a token and correct IP'{

        $restRequest = Invoke-RestMethod -Uri "http://localhost:$port/pgcontrol/pageControl2?string=aString" -Headers $tokenHeader

        it 'Should have a succesful rest call' {
            $restRequest|should -not -be $null
        }

        it 'Should have a returned some inputs' {
            $restRequest.inputs.name |should -be 'string'
        }

        it 'Should have a returned some items' {
            $restRequest.items.count |should -not -be $null
        }

        it 'should have the right results' {
            #$restRequest.items.method |Should -be 'headerCheck'
            $restRequest.items.returnString | Should -be 'aString'
        }
        it 'should have cachedResponse eq false' {
            $restRequest.cachedResponse |Should -be $false
        }
    }

    context 'Page Control Attributes 4 - Disallow IP Address'{
        
        $restRequest = $null
        it 'Should not have a current restRequest' {
            $restRequest|should -be $null
        }
        try{
            $restRequest = Invoke-RestMethod -Uri "http://localhost:$port/pgcontrol/pageControl3?string=aString"
        }catch{
            $responseCode = $_.Exception.Response.StatusCode.Value__
        }

        it 'Should still have no current restRequest' {
            $restRequest|should -be $null
        }

        it 'Should have a responseCode' {
            $responseCode|should -not -be $null
        }

        it 'Should have responsecode of 401 - Access Denied' {
            $responseCode|should -be 401
        }
    }

    context 'Stop service' {
        $restRequest = Invoke-RestMethod -Uri "http://localhost:$port/admin/stop" -Headers $tokenHeader
        it 'Should have responded that it was no longer listening' {
            $restRequest.items.message |should -be 'Server requested to stop listening'
        }
        start-sleep -seconds 5
        $jobStatus = get-job -id $job.id
        it 'Should have stopped the job' {
            $jobStatus.State |Should -be 'Completed'
        }
    }
}



set-location c:\ |out-null
remove-item -Force -Path $testPath -Confirm:$false -Recurse |out-null

describe 'Check Test Folder Removal' {
    it 'should no longer exist ' {
        test-path $testPath | Should -Be $false
    }
}
