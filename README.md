# Copy-PNPNavigation
Copy SharePoint online Navigation menu to another site

You can use this PowerShell module to copy a site navigation menu (TopNavigationBar, Footer, QuickLaunch, SearchNav) to another site. 
The maximum 3 layers of the menu will be copied by this module! 

To use this module Install it by the following command: 
Install-Module -Name Copy-PNPNavigation	

How to use it: 

Copy-PNPNavigation -SourceSite https://contoso.sharepoint.com/sites/SourceSite -BackupDestination C:\FolderOfBackupFile -DestinationSite https://contoso.sharepoint.com/sites/DestinationSite -NavigationLocation TopNavigationBar

SourceSite: The source site that you want to copy from it.
DestinationSite: The Destination site that you want to add Navigation.
BackupDestination: The folder of Excel file. The module will extract a backup file of the navigation to an excel.
NavigationLocation: the location of navigation where you want to copy from the source site. you can choose between
TopNavigationBar, Footer, QuickLaunch, SearchNav
