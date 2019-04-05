# Changelog for Zeus and Commuter Rails Apps

This file documents notable changes to the apps for each release, including:

* core source code shared by all Zeus and Commuter Rails apps
* database schema definitions and updates
* app configuration files

The format of this file is based on
[Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

In short this means that version numbers, visible here and on the login page of the
app match, and have a predictable format indicating how much change from the previous
version has occurred.

The [Unreleased](#[unreleased]) section collects notes for unreleased changes and features, until they are absorbed into a formal release in a version number tagged section below.

## [Unreleased]

- [Fixed] Bug preventing a user of Athena from accessing the default IPA Files app on Medusa

## [7.2.5] - 2019-04-05

- [Fixed] Bug in one-time code pattern prevented correct entry in admin login and e-signature

## [7.2.4] - 2019-04-03

### Fixed
- [Build] Testing improved build process to add branch to Github

## [7.2.3] - 2019-04-03

### Changed
- [UI] Made the one-time code field for login and electronic signatures show the entered digits, to make entry more reliable and avoid issues with password managers attempting to save the code
- [Config] [IPA] Changes to notify MedNav on finalization of phone screener

### Fixed
- [Admin] A special section filter for *IS NULL* no longer returns an error
- [Docs] Fixed issues in the new deployment readme for secure-view installations



## [7.2.2] - 2019-03-29

### Added
- [Docs] Added secure-view readme to support building and installation of server-side programs required for creating previews

### Fixed
- [UI] [Secure-View] Make the HTML preview zoom in a more usable way
- [UI] [Access-Controls] [Secure-View] Manage which roles / users can preview as image, HTML, or can download


## [7.2.1] - 2019-03-29

### Added
- [Secure-View] Provide a secure-viewer directly for users clicking a file link in a filestore container. Just view the pages of documents directly in the browser without having to worry about where files were downloaded, or cleaning them up afterwards.
