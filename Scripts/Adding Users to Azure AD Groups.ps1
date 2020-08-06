#This script is for adding users to Azure AD groups
Connect-AzureAD

#Define and clear variables
$Log = @()
$err = 0
$usr = 0
$groups = @()

#Define groups
#EDIT HERE# Remember to add objectID for groups, these can be found in Azure AD. To add more users, add a comma after the string inside the bracket
$checkGroups = @("Group ObjectID")

#Validating groups
$log += "Validating groups..."
foreach($checkGroup in $checkGroups){
    $groups += try {Get-AzureADGroup -ObjectId $checkGroup} catch {
        if($_ -like "*error*"){
            Write-Host "Error finding group name: $checkGroup. Check the log.csv file generated where you ran this script." -ForegroundColor Red
            $log += "-=ERROR for $checkGroup Start=-`n$_-=ERROR for $checkGroup End=-"
            $log | Out-File .\log.csv
            Exit
        }
    }
}
$log += "Validated all $($checkGroup.Count) groups"
Write-Host "Validated all $($checkGroup.Count) groups."


$log += "Grabbing the users for the scope..."
#EDIT HERE# Add your scope after the "where-object" to define the scope of the users you want to apply the groups to
$refUsers = try {Get-AzureADUser -ALL $true -Filter "accountEnabled eq true" | where-object -property companyName -eq "Company"} catch {
    if($_ -like "*error*"){
        Write-Host "Error finding the scope. Check the log.csv file generated where you ran this script." -ForegroundColor Red
        $log += "-=ERROR for scope Start=-`n$_-=ERROR for scope End=-"
        $log | Out-File .\log.csv
        Exit
    }
}
if($refUsers.Count -eq 0){
    $log += "No reference users found in the scope"
    Write-Host "No reference users found in the scope." -ForegroundColor Red
    $log | Out-File .\log.csv
    Exit
}
$log += "Found $($refUsers.Count) users in the scope"
Write-Host "Found $($refUsers.Count) users in the scope."

foreach($group in $groups){
    #Get the users who're not part of the group
    $log += "Getting difference between scope and members of $($group.DisplayName)..."
    $difUsers = Get-AzureADGroupMember -ObjectId $group.ObjectId -All $true
    $Users = $refUsers | Where-Object {$difUsers.ObjectId -notcontains $_.ObjectId}

    #Check if there are any users to be added, otherwise skip this group
    if($Users.Count -eq 0){
        $log += "All users in the scope were part of $($group.DisplayName)"
        Write-Host "All users in the scope were part of $($group.DisplayName)."
        Continue
    }

    $log += "$($Users.Count) users out of $($refUsers.Count) where not part of $($group.DisplayName)"
    Write-Host "$($Users.Count) users out of $($refUsers.Count) where not part of $($group.DisplayName)."

    #Add the users who're not part of the group to the group
    foreach($user in $users){
        $log += "Adding $($user.UserPrincipalName) to $($group.DisplayName)"
        try {Add-AzureADGroupMember -ObjectId $group.ObjectId -RefObjectId $user.ObjectId} catch {
            $log += "-=ERROR for $($user.UserPrincipalName) Start=-`n$_-=ERROR for $($user.UserPrincipalName) End=-"
            $err++}
        $usr++
        Write-Host "Made sure the $($group.DisplayName) were added to $usr out of $($users.count) users."
    }
}
Write-host "Script ran with $err errors. Check the log.csv file generated where you ran this script."

#Outputs the log to a file
$log | Out-File .\log.csv
