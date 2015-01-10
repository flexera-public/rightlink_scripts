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

License
-------
See [![MIT License](http://img.shields.io/:license-mit-blue.svg)](LICENSE)
