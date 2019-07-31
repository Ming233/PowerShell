cd "\\protect.ds\jss\PRISM_DEV\DeploymentScripts"
.\PRISM_Migration.ps1 -JSON_File SR38178_deployment_dev_b.json -JSON_File_svnfolder `
        'Developers\Jason\current dev stuff' -JSON_File_svnrevision head -Environment DEV `
        -StepsOutput N
