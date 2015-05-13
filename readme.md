	###############################################################
			#### About the Scripts ####
	###############################################################
This project is an example at how to work with Azure Resource Manager.
It allows automated provisioning of one Active Directory (IaaS), one SQL Server (IaaS) and one Azure Web Site (PaaS). 
As such, it creates an infrastructure with the new approach proposed by ARM.

	########################################################################
			#### Release and Support Status ####
	########################################################################
The project is not supported by Windows Azure support but we are very interested in feedback so please report issues through the GitHub repository.
Please do not forget that Azure Resource Manager is in Preview.

	###########################################################
			#### Prerequisites ####
	###########################################################
Please read this articles (http://azure.microsoft.com/en-us/documentation/articles/powershell-azure-resource-manager/) and follow steps before use this project.

	############################################################
			#### Run the script ####
	############################################################
For an easy start, open a powershell session, move to your local project directory, and run the powershell script .\startup.ps1.
To execute the .\startup.ps1 script, you have to fill these parameters:

	.\Startup.ps1 	-SubscriptionName 	<Your_SubscriptionName> `
			-StorageAccountName 	<Your_StorageAccountName> ` 
			-envName 		<Your_EnvName>

	########################################################################
			#### List of files and comments ####
	########################################################################
- Set-Configuration.ps1 : publish configuration of :
							- Templates files
							- Configurations Files
							- DSC Scripts

- Environment.ps1 : 	Create an environment with :
							- An Active Directory Server
							- An SQL Server with a Database
			Parameters :
							- $envName		# The Environment Name
							- $Location		# The target's Azure Datacenter (ex : "North Europe")
							- $userName		# The user's Name
							- $password		# The user's Password (Also used as the Domain's Password)
							- $databaseName		# the name used for the Database
			Needs :
							- the Azure powershell SDK	(version :	0.8.0+)
							- a JSon template file		(here :		environnement.json)
							- a DSC file			(here : 	eoBootCamp.ps1)
							- a storage account		(variable :	$storagedatafilesName)
							- a container			(variable :	$Container)
							- a souscription		(here : 	"Osiatis CIS - MSDN Dev-Test")
							- T-SQL file for Database creation

- PublisEnv.ps1		Equivalent to Environment.ps1, but designed for Azure Automation
			See https://manage.windowsazure.com/@osiatispracticeazure.onmicrosoft.com#Workspaces/AutomationExtension/Account/PublishEnv_33a2a411-ddca-452b-b6a6-92083f32cd07/Runbook/23919d26-7d93-42ab-862b-2319a3bcd2f3/author
			/!\ Warning /!\ : Azure Automation's functionnement is clearly random

	###########################################################################
			#### Deployment details ####
	###########################################################################

What is pushed? Why? ...

	###########################################################################
			#### Configure your own deployment ####
	###########################################################################

As it is described in the previous section, a lot of different files is used to configure our deployment.
As such, you can configure your own environment.

For this purpose, you need to :
	- Aquire a JSon template describing your environment
	- Fill up the parameter set used by the above
	- Describe the detailed configuration for each virtual machines using DSC script

1) The JSon template file is here called "$TemplateFile". Store the path.
2) The parameters are stored in the "$ParametersFile". It contains two types of parameters :
			- Direct Parameters :		Stored directly. They do not use files. (Usernames, Passwords...)
			- Files Parameters :		As the virtual machines can't read your local files, you need to push them on a storage account.
							Fill in	$DSCFile			(path to your DSC)
								$SQLSetUpConfigurationFile	(path to .ini file)
								$SQLDatabaseFile		(path to .sql file)
								$WebPackageFile			(path to .zip Web package)
3) Choose the Subscription, Location, Storage Account Container where the above files will be stored, and environment name.
4) Run!

Good luck!
(And see help section)


	###########################################################
			#### To Do List ####
	###########################################################
	- Création d'un Web Site
	- Intégration dans Azure Automation
	- Ajout de variables pour le nom de domaine
	- Utilisation du mot de passe user pour SQL
	- Same script using Azure Cli (see http://azure.microsoft.com/en-us/documentation/articles/resource-group-template-deploy/)
		/!\ Warning /!\ : To use Azure Cli's arm mode you have to be identified with an organizational account.

	##################################################
			#### Help ####
	##################################################
Azure Resource Manager
	To see
		# http://azure.microsoft.com/en-us/documentation/articles/powershell-azure-resource-manager/

Powershell DSC
	Tutorials :
		# http://www.powershellmagazine.com/2014/08/05/understanding-azure-vm-dsc-extension/
		# http://blogs.technet.com/b/keithmayer/archive/2014/10/31/end-to-end-iaas-workload-provisioning-in-the-cloud-with-azure-automation-and-powershell-dsc-part-2.aspx
		# http://colinsalmcorner.com/post/install-and-configure-sql-server-using-powershell-dsc	
	DSC ressources kit :
		# https://gallery.technet.microsoft.com/scriptcenter/DSC-Resource-Kit-All-c449312d

Debugging
	ActiveDirectory -Node "eo-ad-bootcamp"		(à ajouter dans le script PS ; permet de créer le MOF)
	run DSC scriptstart-DscConfiguration -PAth .\ActiveDirectory -verbose -Wait
	
SQL Express 2012
	Direct Download		
		http://download.microsoft.com/download/8/D/D/8DD7BDBA-CEF7-4D8E-8C16-D9F69527F909/ENU/x64/SQLEXPRWT_x64_ENU.exe

