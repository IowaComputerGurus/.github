# ICG Organization Level Github Tooling, Configuration & Documentation

## Scripts

This repository contains a number of scripts and lists to help manage things.

### `sync-labels.ps1` - Synnchronize Labels

This is used to enumerate repositories and standardize the labels.  It expects a file `labels.json` to be included at the same path as the file.  There are commandline options to be able to test and then actually apply.

This is used to ensure consistency; we typically do NOT force consistency on "design" projects.

### `sync-templates.ps1` - Used to sync template files

The goal of this is to ensure that all repositories within the org, that are not archived, have a proper/consistent setup.  Helpful for things like release notes, etc.

You can execute with the following command

````
.\Sync-Template.ps1 -TargetFile ".github\workflows\build.yml"
````

Note the expectation is that the path to the target file must MATCH the path in the destination!
