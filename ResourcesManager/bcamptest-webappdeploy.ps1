 
$ResourceGroupName = "bcamptest-ResourceGroup"
$subId = "c2f11af5-4813-40ce-9014-ab4809f733af"
$Location = "North Europe" 
$templatesFolder = "C:\Projects\Repos\OsiatisCIS-AzureAssets\BootCamp2015\ResourcesManager"
$secure_string_pwd = convertto-securestring "Ecosiatis123*" -asplaintext -force

#New-AzureResourceGroup -Verbose `
 #           -Location $Location `
  #          -Name $ResourceGroupName
   
New-AzureRoleAssignment -Verbose `            -Mail bcamptestuser@osiatispracticeazure.onmicrosoft.com `            -RoleDefinitionName Owner `            -ResourceGroupName $ResourceGroupNameNew-AzureResourceGroupDeployment -Verbose -ResourceGroupName $ResourceGroupName `
            -TemplateURI $templatesFolder\bcamptest-web.json `
            `
            -subscriptionId $subId `
            -siteName: "bcamptest-web" `
            -hostingPlanName: "bcamptest-appplan" `
            -serverFarmResourceGroup $ResourceGroupName `
            -siteLocation: $Location `
            -sku: "Free" `
            -workerSize: "0" `
            `
            -serverName: "bcamptest-sql" `
            -serverLocation: $Location `
            -administratorLogin: "bcamptestadmin" `
            -administratorLoginPassword:  $secure_string_pwd `
            -databaseName: "bcamptest-db" `
            -collation: "SQL_Latin1_General_CP1_CI_AS" `
            -edition: "Basic" `
            -requestedServiceObjectiveId: "dd6d99bb-f193-4ec1-86f2-43d3bccbc49c"
            
       

            #maxSizeBytes": "1073741824"
            #-autoscaleEnabled : "false" `
           

            #resourceGroup
            #dbSubscriptionId
            #dbResourceGroup
            
Remove-AzureResourceGroup -Verbose -Name $ResourceGroupName            
        