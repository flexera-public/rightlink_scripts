RightLink Scripts
=================

RightScripts for RightScale's RightLink10 (aka RightLinkLite) agent used in the
Base ServerTemplate and beyond.

This repository contains the collection of RightScrits used in ServerTemplates that go with
the new RightLink10 agent. The scripts for the base ServerTemplate are in the rll subdirectory.

How it Works
------------

This repository masquerades to RightScale as a Chef Cookbook repository but everything here
really are RightScripts, i.e. shell scripts that are executed by the RightScale agent.

The directory structure is kept very simple: each directory of the root contains a collection
of scripts and masquerades as a Chef cookbook. Each such directory contains a set of bash or
ruby scripts (or powershell in the case of Windows) and a Chef metadata.rb file that describes
the scripts as well as the inputs of each on (or attributes in Chef terminology).

Within the RightScale dashboard these scripts can be composed just like Chef recipes and they
will be executed by RightLink 10 (aka RightLinkLite) just like RightScripts. The inputs are
passed via environment variables, therefore their names should be kept flat and, by convention,
in all caps. The input values must be simple strings.

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

In order to modify a script in this repo the recommended first steps are:
- Fork the repo on github and clone the fork to your laptop
- Create a branch (or use master, your choice)
- Make a change, `git commit` the change,
- Set the RS_KEY environment variable to your OAuth key for your account (found in the RS dashboard
  on the `settings>API credentials` page
- Use `./rs_push` to push to github and RightScale, this creates a repository in your RightScale
  account named `rightlink_scripts_<your_branch_name>` and makes RS fetch from github. Note:
  choose your branch name judiciously!
- Ensure you have imported the official _RL10.0.X Linux Base_ ServerTemplate to your
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

For a faster edit&test cycle, you can further clone the git repo onto your server and edit & test
locally on the server as follows:
- SSH to the server and clone your git repo to your home directory or wherever is convenient
- Tell RL10 where to find your cookbook(s), specifically, you need to point RL10 to the directory
  that has your cookbooks as subdirectories. Assuming you cloned the rightlink_scripts repo
  into `/home/rightscale/rightlink_scripts` this would be as follows:
  (_warning, these instructions are untested_)
```
. /var/run/rll-secret
curl -X PUT -g http://localhost:$RS_RLL_PORT/rll/debug/cookbook \
     --data-urlencode path=/home/rightscale/rightlink_scripts
```
  This now means that RL10 expects to find an operational script called `rll::init` in the
  dashboard at `/home/rightscale/rightlink_scripts/rll/init.*`
- Test your scripts by running them from the dashboard or command line using
```
./rs_run rll::my_script
```
- When done, you can `git commit` your changes and push them using the `./rs_push` script, which
  will ensure that the RS platform refetches the respository.
- Note that if you need to clone multiple repos onto your server you cannot tell RL10 to search
  more than one repo for scripts. A work-around is to create a separate directory for RLL that
  contains symlinks to all the cookbook directories you want RL10 to search.
- To troubleshoot the process use the RightLink log audit entry on your server, RL10 logs
  the steps to download cookbooks and then search for the appropriate scripts.

License
-------
See [![MIT License](http://img.shields.io/:license-mit-blue.svg)](LICENSE)
