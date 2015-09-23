RightLink Scripts
=================

RightScripts for RightScale's RightLink10 agent used in the Base ServerTemplate and beyond.

This repository contains the collection of RightScripts used in ServerTemplates that go with
the new RightLink10 agent. The scripts for the base Linux ServerTemplate are in the
`rll` subdirectory, and the scripts for the base Windows ServerTemplate are in the `rlw`
subdirectory. Additional RightScripts are also in `rll-examples` and `rlw-examples`.  Each
RightScript has a comment header providing metadata info in YAML format with the following
fields: `RightScript Name`, `Decription`, and `Inputs`. This headers will be used
to populate these fields when uploaded to the RightScale platform as RightScripts.

How it Works
------------
### RightScripts
The directory structure is kept simple, having Linux RightScripts in the `rll` and `rll-examples`
directories and Windows RightScripts in the `rlw` and `rlw-examples` directories.  The naming of
the scripts in this repository is also done for simplicity. The RightScript name that is to be
shown in the RightScale dashboard should be under the `RightScript Name` field in the YAML
formatted comment header, described earlier.

### Chef Cookbook
This repository masquerades to RightScale as a Chef Cookbook repository but everything here
really are RightScripts, i.e. shell scripts that are executed by the RightScale agent.

The directory structure is kept very simple: each directory of the root contains a collection
of scripts and masquerades as a Chef cookbook. Each such directory contains a set of bash or
ruby scripts (or powershell in the case of Windows) and a Chef metadata.rb file that describes
the scripts as well as the inputs of each on (or attributes in Chef terminology).

Within the RightScale dashboard these scripts can be composed just like Chef recipes and they
will be executed by RightLink 10 just like RightScripts. The inputs are passed via environment
variables, therefore their names should be kept flat and, by convention, in all caps. The
input values must be simple strings.

In terms of naming, in order to associate a file with a recipe name RightLink searches for the
first file that matches `recipename.*` and that is executable, thus you are free to add `.sh`,
`.rb`, or `.ps1` extensions. (However, ensure your editor doesn't save backup files by adding
a `~` or `.bak` at the end of filenames.)

Note that there are no "attachments" like for "regular" RightScripts, however, the entire
cookbook directory with any subdirectories is downloaded to the instance, so you can easily have
an "attachments" subdir with stuff in it, up to the size limit of a cookbook. Your scripts will
be executed with their working directory set to the cookbook dir, e.g., a reference to
something like "./templates/daemon.conf" is entirely reasonable.

Developer Info
--------------
### RightScripts
In order to modify a script in this repo and update the matching RightScript, a few steps will need
to be done.  Installation of `ruby 2.0` and `bundler` gem is required.

The following setup should only need to be done once:

1. Import the official _RightLink 10.X.X Linux Base_ or _RightLink 10.X.X Windows Base_ ServerTemplate into
   your account. This will also import the RightScripts.
1. Fork the repo on github and clone the fork to your workstation
1. Create a branch (or use master, your choice)
1. Run `bundle install` to install the `rightscript_sync` gem used to update the RightScript
1. From the RightScale Dashboard, go to `Settings -> API Credentials` and obtain the `Refresh Token`
   and `Token Endpoint`
1. Create a directory and file `~/.right_api_client/login.yml` consisting of:

   ```yml
   :refresh_token: <Refresh Token>
   :api_url: <Protocol and hostname of Token Endpoint only, ie https://us-3.rightscale.com>
   ```

These next steps are the suggested workflow:

1. Make a change, `git commit` the change
1. Run `bundle exec rightscript_sync upload path/to/script` to update the HEAD revision of the RightScript.
   Remember, the name of the RightScript to update should be provided under `RightScript Name` in the YAML
   formatted header.
   * example: `bundle exec rightscript_sync upload rll/collectd.sh`

### As a Chef Cookbook
In order to modify a script in this repo and treat it as a Chef Cookbook, the recommended first steps are:
- Fork the repo on github and clone the fork to your workstation
- Create a branch (or use master, your choice)
- Make a change, `git commit` the change,
- Set the RS_KEY environment variable to your OAuth key for your account (found in the RS dashboard
  on the `settings>API credentials` page
- Use `./rs_push` to push to github and RightScale, this creates a repository in your RightScale
  account named `rightlink_scripts_<your_branch_name>` and makes RS fetch from github. Note:
  choose your branch name judiciously!
- Ensure you have imported the official _RightLink 10.0.X Linux Base_ ServerTemplate to your
  account (for the right _X_)
- Run `./rs_make_st -s 'RL10.0.X Linux Base' -c` to clone the official base ServerTemplate
  your branch name will be appended to the name of the cloned ST) and have it changed to use
  your repository
- In the RightScale dashboard, find your ST, create a server from it, and launch it, it now
  uses your modified scripts

When to use...
- `rs_push`: use instead of git push whenever you want the changes to be pushed to RightScale
  so a launching or running server can fetch the updated scripts and run them
- `rs_make_st`: use whenever you push a new branch of a repo and you thus need a ServerTemplate
  that uses the scripts in the new branch, once you've created the ST and you make updates to
  your branch you can use just `rs_push`, you don't need a fresh ST each time
- `rs_make_st -c`: the -c option clones the ServerTemplate, you need this option when you cannot
  modify the HEAD revision of the ST (e.g. you imported the ST), or when you do not want to
  change the HEAD revision. Without the `-c` option the command will repoint the HEAD revision
  to your new repo.
- `rs_make_st -r`: the -r option clones all the MCIs in order to change their tags to download
  a different version of RightLink. For example, if the MCIs of your ST point to RL10.0.rc0 and you
  want to try RL10.0.4 you can use `-r 10.0.4`. It will not change MCIs that already use
  the new version, so it's a "safe" option.

For a faster edit&test cycle, you can further clone the git repo onto your server and edit & test
locally on the server as follows:
- SSH to the server and clone your git repo to your home directory or wherever is convenient
- Tell RL10 where to find your cookbook(s), specifically, you need to point RL10 to the directory
  that has your cookbooks as subdirectories. Assuming you cloned the rightlink_scripts repo
  into `/home/rightscale/rightlink_scripts` this would be as follows:
  (_warning, these instructions are untested_)
```
. /var/run/rightlink/secret
curl -X PUT -g http://localhost:$RS_RLL_PORT/rll/debug/cookbook \
     --data-urlencode path=/home/rightscale/rightlink_scripts
```
  This now means that RL10 expects to find an operational script called `rll::my_script` in the
  dashboard at `/home/rightscale/rightlink_scripts/my_script.*`
- Test your scripts by running them from the dashboard or command line using
```
./rs_run rll::my_script
```
- When done, you can `git commit` your changes and push them using the `./rs_push` script, which
  will ensure that the RS platform refetches the respository.
- Note that if you need to clone multiple repos onto your server you cannot tell RL10 to search
  more than one repo for scripts. A work-around is to create a separate directory for RL10 that
  contains symlinks to all the cookbook directories you want RL10 to search.
- To troubleshoot the process use the RightLink log audit entry on your server, RL10 logs
  the steps to download cookbooks and then search for the appropriate scripts.

RightScale Release Process
--------------------------
The release steps for the Linux and Windows Base ServerTemplate at RightScale are as follows:

1. Check out the rightlink_scripts repo
1. Create release branch: `git checkout -b 10.2.0` (use appropriate branch name to match release)
1. Run `bundle exec rightscript_sync upload path/to/script` for each script to be released with the ServerTemplate and commit any of these updated RightScripts.
1. In the RightScale Dashboard, update the ServerTemplates with a new revisions created from committing of the RightScripts.
1. Check the MCIs on the HEAD revision of the ServerTemplates for the correct tags of the current RightLink release.
1. Rename the ServerTemplate and edit the description to match the name of the RightLink release.
1. Commit and publish ST

License
-------
See [![MIT License](http://img.shields.io/:license-mit-blue.svg)](LICENSE)
