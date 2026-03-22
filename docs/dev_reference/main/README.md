# Developer Reference

## General Information

- ["Forking" to a Private Repository](forking_to_a_private_repository.md)
- [Running **rspec** tests](running_rspec_tests.md)

## Testing

- [Testing Documentation Index](../testing/README.md) - Complete guide to feature spec development
  - [Feature Spec Quick Reference](../testing/feature-spec-quick-reference.md) - Essential patterns on one page
  - [Feature Spec Development Guide](../testing/feature-spec-development-guide.md) - Comprehensive patterns and examples
  - [Grant Aims Development Summary](../testing/grant-aims-development-summary.md) - Real implementation case study

## The app UI

- [AJAX Requests and Responses Using Regular Markup](../app-ui/ajax-requests-with-regular-markup.md)
- [UI templates for Master record search results](../app-ui/ui-templates-for-master-record-search-results.md)
- [show_if with embedded_item](../app-ui/show_if_embedded_item.md)

## Getting git log for CHANGELOG

```
git log --format=%b%n --merges new-master..HEAD
```

Copy and paste the relevant messages into the CHANGELOG `## Unreleased` section.

## Samples

- [Sample](../../dev_reference/samples/0_introduction.md)

## Scripted job scripts

Filestore scripted jobs can be run immediately after upload of a file, or on demand by a user. The directory `scripted_job_scripts` provides a controlled location for these scripts to be stored, and in this case contains two examples.

Organizations will most likely maintain their own scripts in an external repo, such as consected/restructure-apps in a `scripted_job_scripts` directory, and provide a symbolic link here when building and deploying.

## REST API

- [API Reference](../../api_reference/main/README.md)
