class ipAssist
{
    [string]$cidr
    [string]$subnetMask
    [int]$netBits
    [string]$networkId
    [string]$firstIpAddress
    [string]$lastIpAddress
    [long]$hostsPerNet

    [long]$startInteger
    [long]$endInteger
    [long]$addressInteger

    [string]$ipBinary
    [string]$smBinary
    [string]$broadcastBinary
    [string]$networkIdbinary
    
    [string]$cidrLookup

    



    ipAssist([string]$cidr)
    {
        $this.cidrLookup = $cidr
        $this.getNetworkDetails($cidr)

    }

    hidden [void] getNetworkDetails($cidr)
    {
        write-verbose 'Getting Network Details'
        $cidrSplit = $cidr.Split('/')
        $ipAddressBase  =$cidrSplit[0]
        $cidrInt = [convert]::toInt32($cidrSplit[1])
        if($cidrInt -gt 32 -or $cidrInt -lt 0)
        {
            throw 'CIDR Invalid'
        }

        write-verbose "Using cidr: $cidrInt and ipBase: $ipAddressBase"
        $this.ipBinary = $this.getBinary($ipAddressBase)
        $this.smBinary = $this.getCidrBinary($cidrInt)
        $this.netBits = $this.smBinary.indexOf('0')
        write-verbose "Netbit: $($this.netbits)"
        if(($this.netBits -gt 1) -and ($this.netbits -lt 32))
        {
            write-verbose 'Working out network values for multiple range'
            $this.firstIpAddress = $this.getDottedDecimal($($this.ipBinary.substring(0,$this.netBits).padRight(31,'0')+0))
            $this.lastIpAddress = $this.getDottedDecimal($($this.ipBinary.substring(0,$this.netBits).padRight(31,'1')+1))
            $this.networkIdbinary = $this.ipBinary.Substring('0',$this.netBits).padRight(32,'0')
            $this.broadcastBinary = $this.ipBinary.Substring('0',$this.netBits).padRight(32,'1')

            $this.networkId = $this.getDottedDecimal($this.networkIdbinary)
            $this.cidr = "$($this.networkId)/$($this.netBits)"

            $this.startInteger = $this.getIpInteger($this.firstIpAddress)
            $this.endInteger = $this.getIpInteger($this.lastIpAddress)
            $this.hostsPerNet = $($this.endInteger - $this.startInteger)+1
        }else{
            write-verbose 'Working out network values for single ip'
            $this.firstIpAddress =  $this.getDottedDecimal($this.ipBinary)
            $this.lastIpAddress = $this.firstIpAddress
            
            $this.startInteger = $this.getIpInteger($this.firstIpAddress)
            $this.endInteger = $this.startInteger
            $this.hostsPerNet = 1
            $this.cidr = $this.cidrLookup

        }

        write-verbose 'Getting actual CIDR and addressInt'

        $this.addressInteger = $([system.convert]::ToInt64("$($this.ipBinary)",2))
        
        $this.subnetMask = $this.getDottedDecimal($this.smBinary)

       


    }

    hidden [long] getIpInteger($ipAddress)
    {

        write-verbose "Getting IPInt for $ipAddress"
        $split = $ipAddress.split(".")
        write-verbose "Split1: $($split[0])"
        #write-host $split[0]
        $1 = $([int]$($split[0]) * 16777216) #[math]::pow(256,3)
        write-verbose "1: $1"
        $2 = $([int]$($split[1]) * 65536) #[math]::pow(256,2)
        $3 = $([int]$($split[2]) * 256)
        $4 = [int]$split[3]
        return $($1 + $2 + $3 + $4)

    }

    hidden [string] getCidrBinary($cidrInt)
    {
        write-verbose "Getting cidrBin for $cidrInt"
        [int[]]$array = (1..32)
        for($i=0;$i -lt $array.length;$i++)
        {
            if($array[$i] -gt $cidrInt)
            {
                $array[$i]='0'

            }else{
                $array[$i]=1
            }
        }
        return $array -join ''
    }

    hidden [string] getDottedDecimal($binary)
    {   
        write-verbose "Getting ipAddress dotNotation for $binary"
        $i = 0
        $dottedDecimal = while($i -le 24)
        {
            $convert = [string]$([convert]::toInt32($binary.substring($i,8),2))
            $convert
            $i+= 8
        }
        return $dottedDecimal -join '.'
    }

    hidden [string] getBinary($ipAddress)
    {
        write-verbose "Getting binary for $ipAddress"
        $split = $ipAddress.split('.')

        $parts =  foreach($part in $split)
        {
            $([convert]::ToString($part,2).padLeft(8,"0"))
        }

        return $($parts -join '')
    }


    static [long] convertIpToInt($ipAddress)
    {

        write-verbose "Getting IPInt for $ipAddress"
        $split = $ipAddress.split(".")
        #write-verbose "Split1: $($split[0])"
        #write-host $split[0]
        $1 = $([int]$($split[0]) * 16777216) #[math]::pow(256,3)
        #write-verbose "1: $1"
        $2 = $([int]$($split[1]) * 65536) #[math]::pow(256,2)
        $3 = $([int]$($split[2]) * 256)
        $4 = [int]$split[3]
        return $($1 + $2 + $3 + $4)

    }



}

<#Tests
$VerbosePreference = 'silentlycontinue'

[ipAssist]::New('10.0.0.0/8')
[ipAssist]::New('10.0.0.0/28')
[ipAssist]::New('10.0.0.0/32')

[ipAssist]::convertIpToInt('192.168.0.99')
#>