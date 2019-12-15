break
cls

Set-Location C:\PShell\Demos



#region ##### BaseOS PUSH #####

# Sample configuration
Configuration BaseOS {

param ([string[]]$ComputerName = 'localhost')

    Import-DscResource -ModuleName PSDesiredStateConfiguration

	Node $ComputerName {

		WindowsFeature Backup {
			Ensure = 'Present'
			Name   = 'Windows-Server-Backup'
		}
	}
}

BaseOS -ComputerName $Node

#endregion



#region ##### Web PULL SMB #####

Configuration Web {

param ([string[]]$ComputerName = 'localhost')

    Import-DscResource –ModuleName PSDesiredStateConfiguration

	Node $ComputerName {

        WindowsFeature IIS
        {
            Ensure = 'Present'
            Name   = 'Web-Server'
        }
	}
}

Web -ComputerName $Node


#endregion



#region ##### InfoSec PULL HTTPS #####

Configuration InfoSec {

param ([string[]]$ComputerName = 'localhost')

    Import-DscResource –ModuleName PSDesiredStateConfiguration

	Node $ComputerName {

        Group Admins
        {
            Ensure     = 'Present'
            GroupName  = 'InfoSecBackDoor'
            Members    = 'Administrator'
        }
	}
}

InfoSec -ComputerName $Node

#endregion

