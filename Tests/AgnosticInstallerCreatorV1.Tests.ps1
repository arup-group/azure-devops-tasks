BeforeAll {
    $root = ".\AgnosticInstallerCreator\AgnosticInstallerCreatorV1"
    Push-Location
    Set-Location $root
    . ./TaskFunctions.ps1
}

AfterAll {
    Pop-Location
}

Describe 'TaskFunctions' {

    # Context 'ReadTaskArguments' {

    #     BeforeAll {
    #         Mock Get-VstsTaskVariable { return "all-repos-dir" } -ParameterFilter { $Name -eq "Build.SourcesDirectory" }
    #         Mock Get-VstsInput { return "test_repo" } -ParameterFilter { $Name -eq "repoName" }
    #         Mock Get-VstsInput { return "src\test-project" } -ParameterFilter { $Name -eq "projectParentPath" }
    #         Mock Get-VstsInput { return "TestProject" } -ParameterFilter { $Name -eq "projectName" }
    #     }
    
    #     It 'Should read task arguments correctly' {
    #         $taskArgs = ReadTaskArguments

    #         # projectParentPath should be prepended with repoPath
    #         $taskArgs.SourcesDirectory | Should -Be "all-repos-dir"
    #         $taskArgs.RepoName | Should -Be "test_repo"
    #         $taskArgs.RepoPath | Should -Be "all-repos-dir\test_repo"
    #         $taskArgs.ProjectParentPath | Should -Be "all-repos-dir\test_repo\src\test-project"
    #         $taskArgs.ProjectName | Should -Be "TestProject"
    #         $taskArgs.RandomProperty | Should -Be $null
    #     }

    #     It 'projectParentPath should not be prepended with repoPath' {
    #         # if it already starts with it
    #         Mock Get-VstsInput { return "all-repos-dir\test_repo\test_project_path" } -ParameterFilter { $Name -eq "projectParentPath" }

    #         $taskArgs = ReadTaskArguments

    #         $taskArgs.ProjectParentPath | Should -Be "all-repos-dir\test_repo\test_project_path"

    #         # if projectParentPath starts with "C:"
    #         Mock Get-VstsInput { return "C:\test_project_path" } -ParameterFilter { $Name -eq "projectParentPath" }

    #         $taskArgs = ReadTaskArguments

    #         $taskArgs.ProjectParentPath | Should -Be "C:\test_project_path"
    #     }

    #     It 'projectParentPath should be prepended with repoPath' {
    #         Mock Get-VstsTaskVariable { return "C:\src_dir" } -ParameterFilter { $Name -eq "Build.SourcesDirectory" }
    #         Mock Get-VstsInput { return "foo\src_dir\test_repo\test_project_path" } -ParameterFilter { $Name -eq "projectParentPath" }

    #         $taskArgs = ReadTaskArguments

    #         $taskArgs.ProjectParentPath | Should -Be "C:\src_dir\test_repo\foo\src_dir\test_repo\test_project_path"
    #     }
    # }

    It 'Should read the version' {
        Mock Get-VstsInput { return "1.2.3.4" } -ParameterFilter { $Name -eq "fullVersion" }

        $version = ReadVersion

        $version.Major | Should -Be "1"
        $version.Minor | Should -Be "2"
        $version.Patch | Should -Be "3"
        $version.Build | Should -Be "4"
        $version.anotherRandoProp | Should -Be $null
    }

    # It 'Should fail to read a version that does not contain 4 numbers' {
    #     Mock Get-VstsInput { return "1" } -ParameterFilter { $Name -eq "fullVersion" }
    #     ReadVersion -ErrorVariable errors -ErrorAction SilentlyContinue
    #     $errors.Count | Should -Be 1

    #     Mock Get-VstsInput { return "1.2.3" } -ParameterFilter { $Name -eq "fullVersion" }
    #     ReadVersion -ErrorVariable errors -ErrorAction SilentlyContinue
    #     $errors.Count | Should -Be 1

    #     Mock Get-VstsInput { return "1.2.3." } -ParameterFilter { $Name -eq "fullVersion" }
    #     ReadVersion -ErrorVariable errors -ErrorAction SilentlyContinue
    #     $errors.Count | Should -Be 1

    #     Mock Get-VstsInput { return "..." } -ParameterFilter { $Name -eq "fullVersion" }
    #     ReadVersion -ErrorVariable errors -ErrorAction SilentlyContinue
    #     $errors.Count | Should -Be 1

    #     Mock Get-VstsInput { return "1.2.3.4.5" } -ParameterFilter { $Name -eq "fullVersion" }
    #     ReadVersion -ErrorVariable errors -ErrorAction SilentlyContinue
    #     $errors.Count | Should -Be 1
    # }
    
    # It 'Should create installer directories using the input correctly' {
    #     $taskArgs = @{
    #         ProjectName="TestProject"
    #         RepoPath="C:\src-dir\test-repo"
    #     }
    #     $version = @{
    #         Major = "1"
    #         Minor = "2"
    #         Patch = "3"
    #     }

    #     $installerInfo = GetInstallerInfo $taskArgs $version

    #     $installerInfo.BuilderDirectory | Should -Be "C:\src-dir\test-repo\installer-builder"
    #     $installerInfo.TargetDirectory | Should -Be `
    #         "C:\src-dir\test-repo\installer-builder\testproject-1.2\TARGETDIR\Program Files\Oasys\TestProject 1.2"
    # }

    # It 'Should delete the installer directory if it exists' {
    #     # Make installer directory with one file
    #     $sourcesDirectory = "."
    #     $installerDirectory = "$sourcesDirectory\installer"
    #     $fileName = "$installerDirectory\testfile.txt"

    #     New-Item -Path $installerDirectory -ItemType "directory"
    #     New-Item -Path $fileName -ItemType "file"
    
    #     $installerDirectory | Should -Exist
    #     $fileName | Should -Exist
        
    #     ClearInstallerDirectory $sourcesDirectory $installerDirectory

    #     $fileName | Should -Not -Exist
    #     $installerDirectory | Should -Not -Exist
    # }
}