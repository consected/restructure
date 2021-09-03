# Filestore File Filters

## Introduction

**Filestore File Filters** control which users and roles can view and upload files to specific types of *Filestore Container*.

Files are filtered based on their folders and filenames, and may be applied to both regular *stored files*, and *archived files* that represent files extracted from a stored Zip or other archive file format.

**NOTE:** by default no files are viewable in a *Filestore Container* without a file filter being applied.

Administration is provided in [Filestore: File Filters](/admin/nfs_store/filter/filters)

## Configurations

All filter use [Regular Expressions](regular_expressions.md) to match file paths.

Containers with no filters defined (for the app, role or user) for the current user will always return no files.

To match any file in a container (allow all to be viewed), use the filter `.*`

Remember that to match a `.` (dot) character, the character must be escaped in a regex `\.`

File paths follow Unix standards. Therefore file path separators are forward-slash `/`. These characters do not need to be escaped (unlike many scripting languages that use `/.../` to indicate a regex definition)

*Stored Files* and *Archived Files* to be filtered against have an initial forward-slash `/` character. Be sure to use this if matching from the start of the string with the caret (start of line) symbol.

For example, `^/folder1/somefile.doc` matches the file path **/folder1/somefile.doc** but not **/root/folder1/somefile.doc**. `/folder1/somefile.doc` matches both.

For example, a file in the root directory of the container named **00000.dcm** will be matched by filter `^/0+\.dcm` or `/0+\.dcm` but will not be matched by `^0+\.dcm` since it does not expect to see the initial forward-slash. `00000.dcm` would match the file, but would also match **X00000.dcm**
