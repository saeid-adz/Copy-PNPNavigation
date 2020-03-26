
Function Copy-PNPNavigation {
 
    Param (
    [parameter(Mandatory = $True)]
    [String]$SourceSite,

    [parameter(Mandatory = $True)]
    [String]$BackupDestination,

    [parameter(Mandatory = $False)]
    [String]$DestinationSite,

    [Parameter(Mandatory=$true)]
    [ValidateSet("TopNavigationBar","Footer", "QuickLaunch", "SearchNav")]
    [String]$NavigationLocation

    )

    Write-Host "Check for Modules" -ForegroundColor Yellow
    if (Get-Module -ListAvailable -Name ImportExcel) {
        Import-Module -Name ImportExcel
         
    }
     else {
         Write-Host "Installing Excel module..." -ForegroundColor Yellow
      Install-Module -Name ImportExcel -Force
     }

     if (Get-Module -ListAvailable -Name SharePointPnPPowerShellOnline) {
        Import-Module -Name SharePointPnPPowerShellOnline
         
    }
     else {
        Write-Host "Installing PNP Online module..." -ForegroundColor Yellow
      Install-Module -Name SharePointPnPPowerShellOnline -Force
     }
     

     Write-Host ""
     Write-Host "Installing PNP Online module..." -ForegroundColor Yellow
     Write-Host ""
    $FileDestination = "$BackupDestination"+"\SiteNavigationBackup.xlsx"

    Write-Host ""
     Write-Host "Connecting to the Source Site..." -ForegroundColor Yellow
     Write-Host ""
    Connect-PnPOnline -Url $SourceSite -UseWebLogin
    
$MainNavigationData = Get-PnPNavigationNode  -Location $NavigationLocation

     Write-Host ""
     Write-Host "Getting Navigation information, Please wait..." -ForegroundColor Yellow
     Write-Host ""
foreach ($MainMenu in $MainNavigationData) {

    $ManinMenuID = $MainMenu.Id
    $MainMenuTitle = $MainMenu.Title 
    $MainMenuURL = $MainMenu.Url

    $FirstSubMenu = Get-PnPNavigationNode -Id  $ManinMenuID
    $FirstSubMenuChilder = $FirstSubMenu.Children

    $Export = [pscustomobject]@{
        MenuID       	    = $ManinMenuID
        MenuTitle			= $MainMenuTitle
        MenuURL     	    = $MainMenuURL
        MenuParent          = ""
        MenuPOS 			= "MainMenu"
        
        
    }
    $Export | Export-Excel -Path $FileDestination -Append

    foreach ($FirstSubMenuChild in $FirstSubMenuChilder) {

        $FirstSubMenuID = $FirstSubMenuChild.Id
        $FirstSubMenuTitle = $FirstSubMenuChild.Title 
        $FirstSubMenuURL = $FirstSubMenuChild.Url

        $SecondSubMenu = Get-PnPNavigationNode -Id $FirstSubMenuID
        $SecondSubMenuChilder = $SecondSubMenu.Children

        $Export = [pscustomobject]@{
            MenuID       	    = $FirstSubMenuID
            MenuTitle			= $FirstSubMenuTitle
            MenuURL     	    = $FirstSubMenuURL
            MenuParent          = $MainMenu.Id
            MenuPOS 			= "FirstSubMenu"
            
            
        }
        $Export | Export-Excel -Path $FileDestination -Append

        foreach ($SecondSubMenuChild in $SecondSubMenuChilder) {

            $SecondSubMenuID = $SecondSubMenuChild.Id 
            $SecondSubMenuTitle = $SecondSubMenuChild.Title
            $SecondSubMenuURL = $SecondSubMenuChild.Url

           $Export = [pscustomobject]@{
                MenuID       	    = $SecondSubMenuID
                MenuTitle			= $SecondSubMenuTitle
                MenuURL     	    = $SecondSubMenuURL
                MenuParent          = $FirstSubMenuID
                MenuPOS 			= "SecondSubMenu"
                
                
            }
            $Export | Export-Excel -Path $FileDestination -Append
    
            
        }
        
    }

    
}
     Write-Host ""
     Write-Host "Backup process is done, you can find the backup file in the destionation folder!" -ForegroundColor Green
     Write-Host ""


If ($DestinationSite) {

     Write-Host ""
     Write-Host "Connecting to the Destination Site..." -ForegroundColor Yellow
     Write-Host ""
Connect-PnPOnline -Url $DestinationSite -UseWebLogin


$ExcelBackupFile = Import-Excel -Path $FileDestination

#Main Menu Scope
##############################################################################
$MainMenuScope = $ExcelBackupFile | Where-Object {$_.MenuPOS -eq "MainMenu"}
$Path= $env:TEMP

     Write-Host ""
     Write-Host "Restoring Navigation to the destination site, Please wait..." -ForegroundColor Yellow
     Write-Host ""

foreach ($MainMenu in $MainMenuScope) {

     $MenuTitle = $MainMenu.MenuTitle
     $MenuUrl = $MainMenu.MenuURL
     $MenuID = $MainMenu.MenuID

     $MainMenu = Add-PnPNavigationNode -Location $NavigationLocation -Title $MenuTitle -Url $MenuUrl -External
     $MainMenuNewId = $MainMenu.Id

     $TempExport = [pscustomobject]@{
        MenuID          	    = $MainMenuNewId
        MenuTitle		    	= $MenuTitle
        OldID                   = $MenuID
        
    }
    $TempExport | Export-Excel -Path "$Path\TempExport.xlsx" -Append

    
}

Write-Host ""
Write-Host "Main-Menu Restored successfully!" -ForegroundColor Green
Write-Host ""
##############################################################################

#First Sub-Menu Scope

##############################################################################
$FirstSubMenuScope = $ExcelBackupFile | Where-Object {$_.MenuPOS -eq "FirstSubMenu"}
$ImportTempScop = Import-Excel -Path "$Path\TempExport.xlsx"

foreach ($FirstSubMenu in $FirstSubMenuScope) {

    $FirstSubTitle = $FirstSubMenu.MenuTitle
    $FirstSubUrl = $FirstSubMenu.MenuURL
    $FirstSubID = $FirstSubMenu.MenuID 
    $FirstSubOldParentId = $FirstSubMenu.MenuParent

    foreach ($Temp in $ImportTempScop) {
        $TempOldID = $Temp.OldID

        If ($FirstSubOldParentId -eq $TempOldID) {

            $FirstSub = Add-PnPNavigationNode -Location $NavigationLocation -Title $FirstSubTitle -Url $FirstSubUrl -Parent $Temp.MenuID -External
            $FirstSubNewId = $FirstSub.Id

            $TempExport = [pscustomobject]@{
                MenuID          	    = $FirstSubNewId
                MenuTitle		    	= $FirstSubTitle 
                OldID                   = $FirstSubID
                
            }
            $TempExport | Export-Excel -Path "$Path\TempExport.xlsx" -Append
        }

        
    }
    
}
Write-Host ""
Write-Host "First Sub-Menu Restored successfully!" -ForegroundColor Green
Write-Host ""
##############################################################################

#Second Sub-Menu Scope

##############################################################################

$SecondSubMenuScope = $ExcelBackupFile | Where-Object {$_.MenuPOS -eq "SecondSubMenu"}
$ImportTempScop = Import-Excel -Path "$Path\TempExport.xlsx"

foreach ($SecondSubMenu in $SecondSubMenuScope) {

    $SecondSubTitle = $SecondSubMenu.MenuTitle
    $SecondSubUrl = $SecondSubMenu.MenuURL
    $SecondSubID = $SecondSubMenu.MenuID 
    $SecondSubOldParentId = $SecondSubMenu.MenuParent

    foreach ($Temp in $ImportTempScop) {
        $TempOldID = $Temp.OldID

        If ($SecondSubOldParentId -eq $TempOldID) {

            $SecondSub = Add-PnPNavigationNode -Location $NavigationLocation -Title $SecondSubTitle -Url $SecondSubUrl -Parent $Temp.MenuID -External
            $FirstSubNewId = $FirstSub.Id

            $TempExport = [pscustomobject]@{
                MenuID          	    = $SecondSubNewId
                MenuTitle		    	= $SecondSubTitle 
                OldID                   = $SecondSubID
                
            }
            $TempExport | Export-Excel -Path "$Path\TempExport.xlsx" -Append
        }

        
    }
    
}
Write-Host ""
Write-Host "Second Sub-Menu Restored successfully!" -ForegroundColor Green
Write-Host ""

Remove-Item -Path "$Path\TempExport.xlsx" -Recurse
Disconnect-PnPOnline
Write-Host ""
Write-Host "All process finished successfully!" -ForegroundColor Green
Write-Host "PNP Session is disconnected!" -ForegroundColor Yellow
Write-Host ""



} Else {
    Write-Host ""
    Write-Host "You skip the restore process!" -ForegroundColor Yellow
    Write-Host ""
}

}