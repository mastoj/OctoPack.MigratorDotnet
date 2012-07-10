param($installPath, $toolsPath, $package, $project)

Import-Module (Join-Path $toolsPath "MSBuild.psm1")

function Delete-Temporary-File 
{
    Write-Host "Delete temporary file"

    $project.ProjectItems | Where-Object { $_.Name -eq 'OctoPack-Readme.txt' } | Foreach-Object {
        Remove-Item ( $_.FileNames(0) )
        $_.Remove() 
    }
}

function Get-RelativePath ( $folder, $filePath ) 
{
    Write-Verbose "Resolving paths relative to '$Folder'"
    $from = $Folder = split-path $Folder -NoQualifier -Resolve:$Resolve
    $to = $filePath = split-path $filePath -NoQualifier -Resolve:$Resolve

    while($from -and $to -and ($from -ne $to)) {
        if($from.Length -gt $to.Length) {
            $from = split-path $from
        } else {
            $to = split-path $to
        }
    }

    $filepath = $filepath -replace "^"+[regex]::Escape($to)+"\\"
    $from = $Folder
    while($from -and $to -and $from -gt $to ) {
        $from = split-path $from
        $filepath = join-path ".." $filepath
    }
    Write-Output $filepath
}

function Install-Targets ( $project, $importFile )
{
    Write-Host ("Installing OctoPack Targets file import into project " + $project.Name)

    $buildProject = Get-MSBuildProject

    $buildProject.Xml.Imports | Where-Object { $_.Project -match "OctoPack" } | foreach-object {     
        Write-Host ("Removing old import:      " + $_.Project)
        $buildProject.Xml.RemoveChild($_) 
    }

    $projectItem = Get-ChildItem $project.FullName
    Write-Host ("The current project is:   " + $project.FullName)
    Write-Host ("Project parent directory: " + $projectItem.Directory)
    Write-Host ("Import will be added for: " + $importFile)

    $target = $buildProject.Xml.AddImport( $importFile )

    $project.Save() 

    Write-Host ("Import added!")
}

function Get-OctoPackTargetsPath ($project) {
    $projectItem = Get-ChildItem $project.FullName
	$importFile = Join-Path $projectItem.Directory ".\octopus\migratordotnet.targets"
    $importFile = Get-RelativePath $projectItem.Directory $importFile 
    return $importFile
}

function Add-OctoPackTargets($project) {
    $solutionDir = Get-SolutionDir
    $octopackToolsPath = (Join-Path $solutionDir .octopack)
    $octopackTargetsPath = (Join-Path $octopackToolsPath OctoPack.targets)

    # Get the target file's path
    $importFile = Join-Path $toolsPath "..\targets\OctoPack.targets"
    $importFile = Resolve-Path $importFile
    
    if(!(Test-Path $octopackToolsPath)) {
        mkdir $octopackToolsPath | Out-Null
    }

    Write-Host "Copying OctoPack.targets $octopackToolsPath"

    Copy-Item "$importFile" $octopackTargetsPath -Force | Out-Null

    Write-Host "Don't forget to commit the .octopack folder"

    $projectItem = Get-ChildItem $project.FullName
    return '$(SolutionDir)\.octopack\OctoPack.targets'
}

function Create-NuSpec($project) {
    Write-Host "Adding .nuspec"
    $templatePath = Join-Path $toolsPath "nuspec-template.xml"
    Install-NuSpec $project.Name $templatePath
    Write-Host ".nuspec added"
}

function Set-CopyLocal($project) {
    $deploy = $project.ProjectItems.Item("octopus").ProjectItems.Item("Deploy.ps1")
    Write-Host "Deploy script found"
    $deploy.Properties.Item("CopyToOutputDirectory").Value = 2
    $targets = $project.ProjectItems.Item("octopus").ProjectItems.Item("migratordotnet.targets")
    Write-Host "Targets file found"
    $targets.Properties.Item("CopyToOutputDirectory").Value = 2
}

function Main 
{
    $importFile = Get-OctoPackTargetsPath $project
    Install-Targets $project $importFile
    Set-CopyLocal $project
    Create-NuSpec $project
    Write-Host "Installation done, update the added nuspec-file with metadata before build"
}

Main
