
# Testing Custom Tasks for Azure Devops Pipelines

We have two ways to test a custom task:
1. Write unit tests with Pester
2. Run the custom task in the command line


## 1. References

* [Pester](https://pester.dev/)
* [VstsTaskSdk Testing and Debugging](powershell/Docs/TestingAndDebugging.md)

## 2. Unit testing with Pester

Pester is a testing and mocking framework for PowerShell. It is already included in Windows 10, so there's no need to install anything!

### How to add unit tests:

1. Create a test file in the `Tests` directory called `<CustomTask>.Tests.ps1`  
    For Example:

    ```bash
    touch "./Tests/CustomTaskV1.Tests.ps1"
    ```

2. Add unit tests following the [Pester framework](https://pester.dev/docs/quick-start#creating-a-pester-test).  
    The basic structure of a test is like this:
    ```powershell
    BeforeAll {
        . .\CustomTask\CustomTaskV1\CustomTaskV1.ps1  # Import your task
    }

    Describe 'CustomTaskV1' { 
        It 'Should print Hello World' {
            $output = DoSomething
            $output | Should -Be "Hello World"
        }
    }
    ```
    ***Note***: Make sure to import your task relative to the root directory.

    Use `Mock` to mock the `Get-Vsts**` functions in your task, or any function you want.
    ```powershell
    Mock Get-VstsTaskVariable { return "mock-srcs-dir" } -ParameterFilter { $Name -eq "Build.SourcesDirectory" }
    Mock Get-VstsInput { return "mock-my-input" } -ParameterFilter { $Name -eq "myInput" }
    ```

    *Read more on [asserts](https://pester.dev/docs/assertions/) and [mocking](https://pester.dev/docs/usage/mocking)*

3. Open Powershell and run Pester using `Invoke-Pester` from the root directory.

    ```powershell
    PS C:\azure-devops-tasks> Invoke-Pester

    Starting discovery in 1 files.
    Discovery found 1 tests in 39ms.
    Running tests.
    [+] CustomTaskV1.Tests.ps1 100ms (25ms|40ms)
    Tests completed in 103ms
    Tests Passed: 1, Failed: 0, Skipped: 0 NotRun: 0
    ```
    Add `-Output Detailed` to produce a more verbose output.
    ```powershell
    PS C:\azure-devops-tasks> Invoke-Pester -Output Detailed

    Pester v5.5.0

    Starting discovery in 1 files.
    Discovery found 1 tests in 6ms.
    Running tests.

    Running tests from 'CustomTaskV1.Tests.ps1'
    Describing CustomTaskV1
    [+] Should print Hello World 61ms (12ms|49ms)
    Tests completed in 159ms
    Tests Passed: 1, Failed: 0, Skipped: 0 NotRun: 0
    ```

## 3. Running the task from the command line

### Run the task

It is possible to test a custom task on your machine using the script `RunTask.ps1`.

To test the task, run the script from the root directory and include the following arguments:

```powershell
PS C:\azure-devops-tasks> .\Tests\scripts\RunTask.ps1 [relative\path\to\parent\folder] [TaskFileName]

# For Example
PS C:\azure-devops-tasks> .\Tests\scripts\RunTask.ps1 .\InstallerCreator\InstallerCreatorV4 InstallerCreatorV4.ps1
```

### Set the input values

The script `RunTask.ps1` uses the `VstsTaskSdk` to invoke the custom task. If any inputs are expected, the script will prompt you to enter values for each input.  

This applies to any variable set using `Get-VstsTaskVariable` or `Get-VstsInput`

Here's an example:
```powershell
PS C:\azure-devops-tasks> .\Tests\scripts\RunTask.ps1 .\CustomTask\CustomTaskV1 CustomTaskV1.ps1

Running .\CustomTask\CustomTaskV1\CustomTaskV1.ps1...

##vso[task.debug]VstsTaskSdk 0.11.0 commit 7ff27a3e0bdd6f7b06690ae5f5b63cb84d0f23f4
'Build.SourcesDirectory' task variable: my\src\dir
'myInput' input: "My input value"
'anotherInput' input: "Another input value"
...
```


***Note***: It will prompt you only once per powershell session. Everything you enter will be stored in a cache in the shell and will be reused the next time you invoke the task.

### Change the input values

If you want to change the values for the inputs without creating a new session, you can set the values as environment variables:

For example, we want to change the values for the task variable `Build.SourcesDirectory` and the input `myInput`:
```powershell
# Set value for Build.SourcesDirectory
PS > $env:BUILD_SOURCESDIRECTORY = "new sources dir"

# Set value for myInput
PS > $env:INPUT_MYINPUT = "new value"
```

The next time you invoke the task with `RunTask.ps1`, the values will be updated.

### [Optional] Write your test values in a `.env`

If you want, you can create a `test.env` file in the custom task directory and pass that into `RunTask.ps1`. It will read from the file and set those as `$env` variables for you.

#### Example:

1. Create the file `test.env` and add environment variables corresponding to the expected inputs for your task
    ```
    BUILD_SOURCESDIRECTORY=test\srcs\dir
    INPUT_MYINPUT="my value"
    INPUT_ANOTHERINPUT=another\value
    ```

2. Pass the name of the `.env` file to `RunTask.ps1`
    ```powershell
    PS C:\azure-devops-tasks> .\Tests\scripts\RunTask.ps1 .\CustomTask\CustomTaskV1 CustomTaskV1.ps1 test.env
    ```
3. Verify that the script outputs a list of the contents of `test.env`

    ```powershell
    PS C:\azure-devops-tasks> .\Tests\scripts\RunTask.ps1 .\CustomTask\CustomTaskV1 CustomTaskV1.ps1 test.env

    Setting the following env variables as input:

    BUILD_SOURCESDIRECTORY=test\srcs\dir
    INPUT_MYINPUT="my value"
    INPUT_ANOTHERINPUT=another\value

    Running .\AgnosticInstallerCreator\AgnosticInstallerCreatorV1\AgnosticInstallerCreator.ps1...
    ```