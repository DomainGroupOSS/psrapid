@{
  ModuleVersion = '1.0.2'
  RootModule = 'psrAPId.psm1'
  AliasesToExport = @()
  FunctionsToExport = @()
  CmdletsToExport = @()
  PowerShellVersion = '5.0.0.0'
  PrivateData = @{
    builtBy = 'Adrian.Andersson'
    moduleRevision = '1.0.1.1'
    builtOn = '2019-04-05T18:31:29'
    PSData = @{
      LicenseUri = 'https://github.com/DomainGroupOSS/psrapid/blob/master/LICENSE'
      Tags = @('Domain','API','Framework','psCore','linux')
      ProjectUri = 'https://github.com/DomainGroupOSS/psrapid'
      IconUri = 'https://github.com/DomainGroupOSS/psrapid/blob/master/icon.png'
    }
    bartenderCopyright = '2019 Domain Group'
    pester = @{
      time = '00:00:19.5192102'
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
