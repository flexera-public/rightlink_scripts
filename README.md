RightLink Scripts
=================

RightScripts for RightScale's RightLink10 agent used in the Base ServerTemplates and beyond.

This repository contains the collection of RightScripts used in ServerTemplates that go with
the new RightLink10 agent. The scripts for the base Linux ServerTemplate are in the
`rll` subdirectory, and the scripts for the base Windows ServerTemplate are in the `rlw`
subdirectory. Additional RightScripts are also in `rll-examples` and `rlw-examples`.  Each
RightScript has a comment header providing metadata info in YAML format with the following
fields: `RightScript Name`, `Description`, and `Inputs`. These headers will be used
to populate these fields when uploaded to the RightScale platform as RightScripts.

How it Works
------------
The directory structure is kept simple, having Linux RightScripts in the `rll` and `rll-examples`
directories and Windows RightScripts in the `rlw` and `rlw-examples` directories.  The naming of
the scripts in this repository is also done for simplicity. The RightScript name that is to be
shown in the RightScale dashboard should be under the `RightScript Name` field in the YAML
formatted comment header, described earlier.

Developer Info
--------------
In order to modify a script in this repo and update the matching RightScript, a few steps will need
to be done.

The following setup should only need to be done once to setup the development environment:

1. In the RightScale dashboard, import the official [_RightLink 10.X.X Linux Base_](https://www.rightscale.com/library/server_templates/RightLink-10/lineage/53250) or [_RightLink 10.X.X Windows Base_](https://www.rightscale.com/library/server_templates/RightLink-10/lineage/55964) ServerTemplate into your account. This will also import the RightScripts.
2. While still in the RightScale dashboard, clone the imported ServerTemplate, allowing changes to be made to the HEAD revision.
3. Fork this repo on github and clone the fork to your workstation.
4. Create a branch (or use master, your choice).
5. Install and configure [right_st](https://github.com/rightscale/right_st#installation) for your platform somewhere that is in your `PATH`.

These next steps are the suggested workflow:

1. Make a change and `git commit` the change
2. Run `right_st rightscript upload path/to/script` to update the HEAD revision of the RightScript. Remember, the name
   of the RightScript to update should be provided under `RightScript Name` in the YAML formatted header.
   * example: `right_st rightscript upload rll/enable-monitoring.sh`
3. Verify the HEAD revision of the RightScript has been synced with your git commit and is identical.

RightScale Release Process
--------------------------
The release steps for the Linux and Windows Base ServerTemplate at RightScale are as follows:

1. Check out the rightlink_scripts repo
2. Create release branch: `git checkout -b 10.2.0` (use appropriate branch name to match release)
3. Run `right_st rightscript upload path/to/script` for each script to be released with the ServerTemplate and commit
   any of these updated RightScripts.
4. In the RightScale Dashboard, update the ServerTemplates with the new RightScript revisions created from the previous step.
5. Check the MCIs on the HEAD revision of the ServerTemplates for the correct tags of the current RightLink release.
6. Rename the ServerTemplate and edit the description to match the name of the RightLink release.
7. Commit and publish ST

License
-------
See [![MIT License](http://img.shields.io/:license-mit-blue.svg)](LICENSE)
