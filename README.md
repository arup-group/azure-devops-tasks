# OasysRelease Task for Azure Devops Pipelines

There are three version available:

- `InstallerCreatorv1`
  - Currently used for GSA and AdSec.  
  - Doesn't use the SP number in builds.  
  - The version numbers are obtained by looking at the source path of the build.
- `InstallerCreatorv2`
  - Currently used for all of the Geo programs.  
  - Does use the SP number in builds.  
  - The version numbers are obtained by looking at the properties of the program executable.
- `InstallerCreatorv3`
  - An update to `InstallerCreatorV2`.  The _programs64.txt_ list of files required to build an installer is now referenced directly from the _oasys-combined_ repo rather than from the _oasys-windows-installer_ one.  This ensures that the list of files required to build an installer for a program is versioned alongside the code for that program.

## IMPORTANT - After making changes
After making changes, it's important to update the task version in the relevant `task.json` file. For example:

```
"version": {
    "Major": 2,
    "Minor": 1,
    "Patch": 0
}
```

If you change the `Major` version number, then you'll have to update any task entries in the build pipelines in order to use the new version.

If you change the `Minor` or `Patch` version numbers, then the new version of the task will be picked up automatically by any new runs of the build pipelines.

## To Check
Check that the task has been updated in Azure Devops.  Go to `Organization -> Extensions` and make sure that you can see the updated version of the `Oasys Installer Create Task`.

## Note
Any re-runs of existing jobs will continue to use the old task.  Instigate a new run if you want to use the new task.


