##################
SCRIPTS : 
- PushResources.ps1 : permet de publier les fichiers de template, de configuration et les scripts DSC
- Environment.ps1 : 
	- créer un environnement avec :
		- 1 Server Active Directory
		- 1 Server SQL Server avec une base de donnée
	- Paramètres :
		- $envName # Nom de l'environnement
		- $Location # Datacenter Azure (ex : "North Europe")
		- $userName # Nom de l'utilisateur
		- $password # Mot de passe de l'utilisateur (également utilisé comme mot de passe du domain)
		- $databaseName # Nom de la base de données
	- Nécessite :
		- le powershell Azure SDK (0.8.0+)
		- un fichier de template JSon (environnement.json)
		- un DSC (eoBootCamp.ps1)
		- un compte de stockage (variable $storagedatafilesName)
		- un container (variable $Container)
		- une souscription ("Osiatis CIS - MSDN Dev-Test")
		- un fichier T-SQL de création d'une base de données
- PublisEnv.ps1
		- Script équivalent à Environment.ps1 et destiné à Azure Automation
		- Goto https://manage.windowsazure.com/@osiatispracticeazure.onmicrosoft.com#Workspaces/AutomationExtension/Account/PublishEnv_33a2a411-ddca-452b-b6a6-92083f32cd07/Runbook/23919d26-7d93-42ab-862b-2319a3bcd2f3/author
		- ATTENTION : Fonctionnement d'Azure automation très aléatoire
		
##################	
ATTENTION : 
	########## RESOLU #####- Le compte SA à un mot de passe imposé : P@ssw0rd.1

##################
RESTE A FAIRE :
	- Création d'un Web Site
	- Intégration dans Azure Automation
	- Ajout de variables pour le nom de domaine
	- Utilisation du mot de passe user pour SQL
	
##################
AIDE 		
	Powershell DSC
		Tuto
			# http://www.powershellmagazine.com/2014/08/05/understanding-azure-vm-dsc-extension/
			# http://blogs.technet.com/b/keithmayer/archive/2014/10/31/end-to-end-iaas-workload-provisioning-in-the-cloud-with-azure-automation-and-powershell-dsc-part-2.aspx
			# http://colinsalmcorner.com/post/install-and-configure-sql-server-using-powershell-dsc	
		DSC ressources kit : https://gallery.technet.microsoft.com/scriptcenter/DSC-Resource-Kit-All-c449312d
			
	Debugging
		ActiveDirectory -Node "eo-ad-bootcamp" (à ajouter dans le script PS ; permet de créer le MOF)
		run DSC script
		start-DscConfiguration -PAth .\ActiveDirectory -verbose -Wait
		
	SQL Express 2012 Direct Download		
		http://download.microsoft.com/download/8/D/D/8DD7BDBA-CEF7-4D8E-8C16-D9F69527F909/ENU/x64/SQLEXPRWT_x64_ENU.exe