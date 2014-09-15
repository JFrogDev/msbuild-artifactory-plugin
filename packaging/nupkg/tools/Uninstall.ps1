param($installPath, $toolsPath, $package, $project)

write-host "Artifactory Package UnInstall Script starting"

$solution = Get-Interface $dte.Solution ([EnvDTE80.Solution2])
$solutionDirectory = Split-Path -parent $solution.FileName
$artifactoryDir = join-path $solutionDirectory '\.artifactory'
#$packageVersion = $package.version.toString()
$rootDir = (Get-Item $installPath)

Function deleteRefFromNuget()
{
	write-host "Deleting reference from Nuget.targets file"

	$nugetPath = join-path $solutionDirectory '\.nuget\NuGet.targets'
	$nugetDoc = New-Object xml
	$nugetDoc.psbase.PreserveWhitespace = true
	$nugetDoc.Load($nugetPath)

	$resolvePath = '$(solutionDir)' + '\.artifactory\targets\resolve.targets'

	foreach ($node in $nugetDoc.Project.Import) {
		if($node.GetAttribute("Project") -eq $resolvePath){
			$nodeToBeDeleted = $node
		}	
	}
	$nugetDoc.Project.RemoveChild($nodeToBeDeleted)
	$nugetDoc.Save($nugetPath);
}

Function deleteRefFromMainProject()
{
  # Grab the loaded MSBuild project for the project
  # Normalize project path before calling GetLoadedProjects as it performs a string based match
  $msbuildProject = [Microsoft.Build.Evaluation.ProjectCollection]::GlobalProjectCollection.GetLoadedProjects([System.IO.Path]::GetFullPath($project.FullName)) | Select-Object -First 1

  $importToRemove = $msbuildProject.Xml.Imports | Where-Object { $_.Project.EndsWith('artifactory.targets') }
  
  # Remove the elements and save the project
  $msbuildProject.Xml.RemoveChild($importToRemove) | out-null
     
  $project.Save()
}

# Verifying that we are inside "Update" process.
if((Test-Path $artifactoryDir )){	
	$artifactoryDirectory = Get-ChildItem C:\Work\nuget-project\multi-project\packages | Where-Object {$_.PSIsContainer -eq $true -and $_.Name -match "Artifactory.*"}
		
	if($artifactoryDirectory.length -gt 1)
	{
		#[System.Windows.Forms.MessageBox]::Show("UnInstall => Update") 		
	}
	else
	{			
		#[System.Windows.Forms.MessageBox]::Show("UnInstall => UnInstall") 
		deleteRefFromNuget
		deleteRefFromMainProject
	}
}
else{
	#[System.Windows.Forms.MessageBox]::Show("UnInstall => UnInstall") 
	deleteRefFromNuget
	deleteRefFromMainProject
}

write-host "Artifactory Package UnInstall Script ended"



