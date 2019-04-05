@{
  ModuleVersion = '1.0.1'
  RootModule = 'psrAPId.psm1'
  AliasesToExport = @()
  FunctionsToExport = @()
  CmdletsToExport = @()
  PowerShellVersion = '5.0.0.0'
  PrivateData = @{
    builtBy = 'Adrian.Andersson'
    moduleRevision = '1.0.0.25'
    builtOn = '2019-04-05T18:28:23'
    PSData = @{
      LicenseUri = 'https://github.com/DomainGroupOSS/psrapid/blob/master/LICENSE'
      Tags = @('Domain','API','Framework','psCore compatible','linux compatible')
      ProjectUri = 'https://github.com/DomainGroupOSS/psrapid'
      IconUri = 'https://github.com/DomainGroupOSS/psrapid/blob/master/icon.png'
    }
    bartenderCopyright = '2019 Domain Group'
    pester = @{
      time = '00:00:19.8738037'
      codecoverage = 0
      passed = '100 %'
    }
    bartenderVersion = '6.1.22'
    moduleCompiledBy = 'Bartender | A Framework for making PowerShell Modules'
  }
  GUID = 'fa5bf6f5-aa2c-4283-8c6e-ca483bb6bb71'
  NestedModules = @('classes.ps1')
  Description = 'A PowerShell API Framework'
  Copyright = '2019 Domain Group'
  CompanyName = 'Domain Group'
  Author = 'Adrian Andersson'
  ScriptsToProcess = 'classes.ps1'
}
