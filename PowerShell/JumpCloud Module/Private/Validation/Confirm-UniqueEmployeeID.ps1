function Confirm-UniqueEmployeeID {
    [CmdletBinding(
    )]
    param (
        [Parameter(Mandatory,
        ValueFromPipelineByPropertyName = $True)]
    [string]
    $employeeIdentifier
        
    )
    begin {

        $ExistingEmployeeIdentifierCheck = Get-Hash_employeeIdentifier_username

        $resultsArrayList = New-Object System.Collections.ArrayList
    
    }
    
    process {

        if ($ExistingEmployeeIdentifierCheck.ContainsKey($employeeIdentifier))
        {
            $Duplicate = [PSCustomObject]@{
                'employeeIdentifier'  = $employeeIdentifier
                'Duplicate' = $True
            }

            $resultsArrayList.add($Duplicate) | Out-Null
            
        }


    }
    
    end {
        return $resultsArrayList
    }
}

