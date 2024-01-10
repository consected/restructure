# Developer Reference

## General Information

- ["Forking" to a Private Repository](forking_to_a_private_repository.md)
- [Running **rspec** tests](running_rspec_tests.md)

## Samples

- [Sample](../../dev_reference/samples/0_introduction.md)

## Scripted job scripts

Filestore scripted jobs can be run immediately after upload of a file, or on demand by a user. The directory `scripted_job_scripts` provides a controlled location for these scripts to be stored, and in this case contains two examples.

Organizations will most likely maintain their own scripts in an external repo, such as consected/restructure-apps in a `scripted_job_scripts` directory, and provide a symbolic link here when building and deploying.
