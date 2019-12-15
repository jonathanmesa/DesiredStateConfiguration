break
cls

Set-Location C:\PShell\Demos

# Reset all LCMs from previous demos
Invoke-Command -ComputerName ms1,ms2,pull -ScriptBlock {
    del C:\Windows\System32\Configuration\metaconfig.mof
}


# Modified from the release notes
[DscLocalConfigurationManager()]
Configuration LCMPartial
{
Param(
    [String]$ComputerName,
    [String]$GUID
)
    Node $ComputerName
    {
        Settings
        {
            RefreshMode                    = 'PULL'
            RefreshFrequencyMins           = 30 
            ConfigurationModeFrequencyMins = 15
            ConfigurationMode              = 'ApplyAndAutoCorrect'
            RebootNodeIfNeeded             = $true
            ConfigurationId                = $GUID
        }

        PartialConfiguration BaseOS
        {
            RefreshMode          = 'PUSH'
            Description          = 'Partial1'
        }

        # Notice DependsOn
        PartialConfiguration Web
        {
            RefreshMode          = 'PULL'
            Description          = 'Partial2'
            ConfigurationSource  = '[ConfigurationRepositoryShare]PullSMB'
            DependsOn            = '[PartialConfiguration]BaseOS'
        }

        # Notice DependsOn, ExclusiveResources
        PartialConfiguration InfoSec
        {
            RefreshMode          = 'PULL'
            Description          = 'Partial3'
            ConfigurationSource  = '[ConfigurationRepositoryWeb]PullHTTPS'
            DependsOn            = '[PartialConfiguration]Web'
            ExclusiveResources   = 'Group\*'
        }

        ConfigurationRepositoryShare PullSMB
        {
            SourcePath           = '\\ms2\SMBPullShare'
        }

        ConfigurationRepositoryWeb PullHTTPS
        {
            ServerURL            = 'https://pull.contoso.com:8080/psdscpullserver.svc'
        }
    }
}


$GUID = (New-Guid).Guid
$Node = 'ms1.contoso.com'

LCMPartial -Computername $Node -GUID $GUID














<#
In the first PUSH if you mix in this property
            #ResourceModuleSource = '[ConfigurationRepositoryWeb]PullHTTPS'
You get an error every time you try to set the LCM. Must be a bug.

VERBOSE: Performing the operation "Start-DscConfiguration: SendMetaConfigurationApply" on target "MSFT_DSCLocalConfigurationManager".
VERBOSE: Perform operation 'Invoke CimMethod' with following parameters, ''methodName' = SendMetaConfigurationApply,'className' = MSFT_DSCLocalConfigurationManager,'namespaceName' = root/Microsoft/Windows/DesiredSt
ateConfiguration'.
VERBOSE: An LCM method call arrived from computer ms12 with user sid S-1-5-21-3864534997-3069656355-577439125-500.
VERBOSE: [ms12]: LCM:  [ Start  Set      ]
VERBOSE: [ms12]: LCM:  [ End    Set      ]
The configuration download manager (null) mentioned in the partial configuration is undefined in the meta configuration. Correct that and try again.
    + CategoryInfo          : ObjectNotFound: (root/Microsoft/...gurationManager:String) [], CimException
    + FullyQualifiedErrorId : MI RESULT 6
    + PSComputerName        : ms2.contoso.com
 
VERBOSE: Operation 'Invoke CimMethod' complete.
VERBOSE: Set-DscLocalConfigurationManager finished in 0.181 seconds.
#>
