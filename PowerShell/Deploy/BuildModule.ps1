Try
{
    # Load config
    . ($PSScriptRoot + '\' + 'Config.ps1')
    # Check to see if module already exists to set version number
    $PowerShellGalleryModule = Find-Module $ModuleName -ErrorAction:('Ignore')
    If ([string]::IsNullOrEmpty($PowerShellGalleryModule))
    {
        $ModuleVersion = '0.0.1'
    }
    Else
    {
        $CurrentModuleVersion = [PSCustomObject]@{
            'Name'    = $PowerShellGalleryModule.Name;
            'Version' = $PowerShellGalleryModule.Version;
            'Major'   = [int]($PowerShellGalleryModule.Version -split '\.')[0];
            'Minor'   = [int]($PowerShellGalleryModule.Version -split '\.')[1];
            'Patch'   = [int]($PowerShellGalleryModule.Version -split '\.')[2];
        }
        $CurrentModuleVersion.Patch = $CurrentModuleVersion.Patch + 1
        $ModuleVersion = ($CurrentModuleVersion.Major, $CurrentModuleVersion.Minor, $CurrentModuleVersion.Patch) -join '.'
    }
    # If the module path already exists then rename it
    If (Test-Path -Path:($Folder_Module)) { Rename-Item -Path:($Folder_Module) -NewName:($ModuleNameOld) }
    # Create required directories
    New-Item -ItemType:('Directory') -Path:($Folder_Module) | Out-Null
    New-Item -ItemType:('Directory') -Path:($Folder_Private) | Out-Null
    New-Item -ItemType:('Directory') -Path:($Folder_Public) | Out-Null
    New-Item -ItemType:('Directory') -Path:($Folder_HelpFiles) | Out-Null
    New-Item -ItemType:('Directory') -Path:($Folder_Tests) | Out-Null
    New-Item -ItemType:('Directory') -Path:($Folder_Docs) | Out-Null
    # Copy the public/exported functions into the public folder, private functions into private folder
    Copy-Item -Path:($Folder_Docs.Replace($Folder_Module, $Folder_Module_Old) + '\' + '*') -Destination:($Folder_Docs) -Recurse -Force
    Copy-Item -Path:($Folder_Tests.Replace($Folder_Module, $Folder_Module_Old) + '\' + '*') -Destination:($Folder_Tests) -Recurse -Force
    Copy-Item -Path:($Folder_Private.Replace($Folder_Module, $Folder_Module_Old) + '\' + '*') -Destination:($Folder_Private) -Recurse -Force
    Copy-Item -Path:($Folder_Public.Replace($Folder_Module, $Folder_Module_Old) + '\' + '*') -Destination:($Folder_Public) -Recurse -Force
    # Create required files
    $FileObject_TestsPs1 = New-Item -ItemType:('File') -Path:($File_TestsPs1_Template -f $Folder_Tests, $ModuleName, $ModuleVersion)
    $FileObject_Ps1xml = New-Item -ItemType:('File') -Path:($File_Ps1Xml)
    $FileObject_Psm1 = New-Item -ItemType:('File') -Path:($File_Psm1)
    # Populate files with content
    $psm1Content = @'
#Get public and private function definition files.
$Public = @(Get-ChildItem -Path:($PSScriptRoot + '\Public\*.ps1') -Recurse -ErrorAction:('SilentlyContinue'))
$Private = @(Get-ChildItem -Path:($PSScriptRoot + '\Private\*.ps1') -Recurse -ErrorAction:('SilentlyContinue'))
#Dot source the files
Foreach ($import In @($Public + $Private))
{
    Try
    {
        . $import.FullName
    }
    Catch
    {
        Write-Error -Message:("Failed to import function $($import.FullName): $_")
    }
}
# Here I might...
# Read in or create an initial config file and variable
# Export Public functions ($Public.BaseName) for WIP modules
# Set variables visible to the module and its functions only
Export-ModuleMember -Function:($Public.Basename)
'@
    $psm1Content | Out-File -FilePath:($File_Psm1)
    ###########################################################################
    $ps1xmlContent = @'
<?xml version="1.0" encoding="utf-8" ?>
<Configuration>
    <ViewDefinitions>
        <View>
            <Name>Default</Name>
            <ViewSelectedBy>
                <TypeName>PSStackExchange.Question</TypeName>
            </ViewSelectedBy>
            <TableControl>
                <TableHeaders>
                    <TableColumnHeader>
                        <Width>48</Width>
                    </TableColumnHeader>
                    <TableColumnHeader>
                        <Width>12</Width>
                    </TableColumnHeader>
                    <TableColumnHeader>
                        <Width>5</Width>
                    </TableColumnHeader>
                    <TableColumnHeader>
                        <Label>Owner</Label>
                        <Width>15</Width>
                    </TableColumnHeader>
                    <TableColumnHeader>
                        <Label>Tags</Label>
                        <Width>20</Width>
                    </TableColumnHeader>
                </TableHeaders>
                <TableRowEntries>
                    <TableRowEntry>
                        <Wrap />
                        <TableColumnItems>
                            <TableColumnItem>
                                <PropertyName>Title</PropertyName>
                            </TableColumnItem>
                            <TableColumnItem>
                                <PropertyName>Answer_Count</PropertyName>
                            </TableColumnItem>
                            <TableColumnItem>
                                <PropertyName>Score</PropertyName>
                            </TableColumnItem>
                            <TableColumnItem>
                                <ScriptBlock>$_.Owner.display_name</ScriptBlock>
                            </TableColumnItem>
                            <TableColumnItem>
                                <ScriptBlock>($_.Tags | Sort-Object) -Join ', '</ScriptBlock>
                            </TableColumnItem>
                        </TableColumnItems>
                    </TableRowEntry>
                </TableRowEntries>
            </TableControl>
        </View>
        <View>
            <Name>Default</Name>
            <ViewSelectedBy>
                <TypeName>PSStackExchange.Answer</TypeName>
            </ViewSelectedBy>
            <TableControl>
                <TableHeaders>
                    <TableColumnHeader>
                        <Width>50</Width>
                    </TableColumnHeader>
                    <TableColumnHeader>
                        <Label>Owner</Label>
                        <Width>20</Width>
                    </TableColumnHeader>
                    <TableColumnHeader>
                        <Width>5</Width>
                    </TableColumnHeader>
                    <TableColumnHeader>
                        <Width>11</Width>
                    </TableColumnHeader>
                </TableHeaders>
                <TableRowEntries>
                    <TableRowEntry>
                        <Wrap />
                        <TableColumnItems>
                            <TableColumnItem>
                                <PropertyName>Share_Link</PropertyName>
                            </TableColumnItem>
                            <TableColumnItem>
                                <ScriptBlock>$_.Owner.display_name</ScriptBlock>
                            </TableColumnItem>
                            <TableColumnItem>
                                <PropertyName>Score</PropertyName>
                            </TableColumnItem>
                            <TableColumnItem>
                                <PropertyName>Is_Accepted</PropertyName>
                            </TableColumnItem>
                        </TableColumnItems>
                    </TableRowEntry>
                </TableRowEntries>
            </TableControl>
        </View>
    </ViewDefinitions>
</Configuration>
'@
    $ps1xmlContent | Out-File -FilePath:($File_Ps1Xml)
    ###########################################################################
    # Create ModuleManifest
    $RootModule = $FileObject_Psm1.Name
    $FormatsToProcess = $FileObject_Ps1xml.Name
    $FunctionsToExport = $Functions_Public.BaseName | Sort-Object
    # Create hash table to store variables
    $FunctionParameters = [ordered]@{ }
    # Add parameters from the script to the FunctionParameters hashtable
    $FunctionParameters.Add('Path', $File_Psd1) | Out-Null

    If (Test-Path -Path:($File_Psd1.Replace($Folder_Module, $Folder_Module_Old)))
    {
        $CurrentModuleManifest = Import-LocalizedData -BaseDirectory:($Folder_Module_Old) -FileName:($File_Psd1.Replace($Folder_Module + '\', ''))
        # Add input parameters from function in to hash table and filter out unnecessary parameters
        $CurrentModuleManifest.GetEnumerator() | ForEach-Object { $FunctionParameters.Add($_.Key, $_.Value) | Out-Null }
        $PrivateDataPSData = $CurrentModuleManifest['PrivateData']['PSData']
        # New-ModuleManifest parameters that come from previous ModuleManifest PrivateData
        $PrivateDataPSData.GetEnumerator() | ForEach-Object {
            If ($FunctionParameters.Contains($_.Key))
            {
                $FunctionParameters[$_.Key] = $_.Value
            }
            Else
            {
                $FunctionParameters.Add($_.Key, $_.Value) | Out-Null
            }
        }
        # Remove previous ModuleManifest PrivateData
        $FunctionParameters.Remove('PrivateData') | Out-Null
        # New-ModuleManifest parameters that are generated from script
        $ModuleManifestParameters = ('RootModule', 'FunctionsToExport', 'ModuleVersion', 'FormatsToProcess')
        ForEach ($ModuleManifestParameter In $ModuleManifestParameters)
        {
            $VariableValue = Get-Variable -Name:($ModuleManifestParameter) -ValueOnly
            If ($FunctionParameters.Contains($ModuleManifestParameter))
            {
                $FunctionParameters[$ModuleManifestParameter] = $VariableValue
            }
            Else
            {
                $FunctionParameters.Add($ModuleManifestParameter, $VariableValue) | Out-Null
            }
        }
    }
    Else
    {
        Write-Warning ('Creating new module manifest. Please populate empty fields: ' + $File_Psd1)
    }
    Write-Debug ('Splatting Parameters');
    If ($DebugPreference -ne 'SilentlyContinue') { $FunctionParameters }
    New-ModuleManifest @FunctionParameters
    # Validate that the module manifest is valid
    $ModuleValid = Test-ModuleManifest -Path:($File_Psd1)
    If ($ModuleValid)
    {
        $ModuleValid
    }
    Else
    {
        $ModuleValid
        Write-Error ('ModuleManifest is invalid!')
    }
}
Catch
{
    $Exception = $_.Exception
    $Message = $Exception.Message
    While ($Exception.InnerException)
    {
        $Exception = $Exception.InnerException
        $Message += "|" + $Exception.Message
    }
    $FullErrorMessage = ($Message + "|" + $_.FullyQualifiedErrorId.ToString() + "|" + $_.InvocationInfo.PositionMessage).Replace("`r", ' ').Replace("`n", ' ')
    Write-Error ($FullErrorMessage)
}
Finally
{
    # If the renamed module path exists then remove it
    If (Test-Path -Path:($Folder_Module_Old)) { Remove-Item -Path:($Folder_Module_Old) -Recurse -Force }
}