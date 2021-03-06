properties {
	$pwd = Split-Path $psake.build_script_file	
	$build_directory  = "$pwd\output\condep-node"
	$configuration = "Release"
	$preString = "-beta"
	$releaseNotes = ""
	$nuget = "$pwd\..\tools\nuget.exe"
}
 
include .\..\tools\psake_ext.ps1

function GetNugetAssemblyVersion($assemblyPath) {
	$versionInfo = Get-Item $assemblyPath | % versioninfo

	return "$($versionInfo.FileMajorPart).$($versionInfo.FileMinorPart).$($versionInfo.FileBuildPart)$preString"
}

task default -depends Build-All, Pack-All
task ci -depends Build-All, Pack-All

task Pack-All -depends Pack-ConDep-Node
task Build-All -depends Clean, ResotreNugetPackages, Build, Create-BuildSpec-ConDep-Node

task ResotreNugetPackages {
	Exec { & $nuget restore "$pwd\..\src\condep-node.sln" }
}
	
task Build {
	Exec { msbuild "$pwd\..\src\condep-node.sln" /t:Build /p:Configuration=$configuration /p:OutDir=$build_directory /p:GenerateProjectSpecificOutputFolder=true}
}

task Clean {
	Write-Host "Cleaning Build output"  -ForegroundColor Green
	Remove-Item $build_directory -Force -Recurse -ErrorAction SilentlyContinue
}

task Create-BuildSpec-ConDep-Node {
	Generate-Nuspec-File `
		-file "$build_directory\condep.node.nuspec" `
		-version $(GetNugetAssemblyVersion $build_directory\ConDep.Node\ConDepNode.exe) `
		-id "ConDep.Node" `
		-title "ConDep.Node" `
		-licenseUrl "http://www.con-dep.net/license/" `
		-projectUrl "http://www.con-dep.net/" `
		-description "ConDepNode is a Node deployed to remote servers by ConDep allowing easy remote interaction with servers." `
		-iconUrl "https://raw.github.com/torresdal/ConDep/master/images/ConDepNugetLogo.png" `
		-releaseNotes "$releaseNotes" `
		-tags "Continuous Deployment Delivery Infrastructure WebDeploy Deploy msdeploy IIS automation powershell remote" `
		-files @(
			@{ Path="ConDep.Node\ConDepNode.exe"; Target="lib/net40"}
		)
}

task Pack-ConDep-Node {
	Exec { & $nuget pack "$build_directory\condep.node.nuspec" -OutputDirectory "$build_directory" }
}