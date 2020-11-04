# Third-Party Libraries Distributed

This project uses third-party libraries or other resources that may
be distributed under licenses different than the project itself.

In the event that we accidentally failed to list a required notice,
please bring it to our attention by creating a new GitHub issue at:

https://github.com/consected/restructure/issues

For any licenses that require disclosure of source, sources are available at
https://github.com/consected/restructure

If any library is distributed under a license that is incompatible with the license of the project,
the recipient should inform the project administrator, remove the library's source code,
and retrieve it from the source location listed instead.


## Distributed Third-Party Javascript / CSS components

Unless otherwise specified, all sources are under the folders: 
vendor/assets/{javascripts|stylesheets|images}/

Over time, these locations may change.


### Bootstrap

Source: https://github.com/twbs/bootstrap

Distributed version: 3.4.1

License: MIT

Notes:

Generated using the Bootstrap Customizer (http://getbootstrap.com/customize/?id=a670b64937a4026dff4cfdaf0f493ca1)

Config saved to config.json and https://gist.github.com/a670b64937a4026dff4cfdaf0f493ca1

Glyphicons is also distributed.


### jquery-ui (includes widget.js)

Source: https://github.com/jquery/jquery-ui

Distributed version: 1.12.1+CommonJS

License: MIT

Notes: A subset is distributed to support jQuery File Upload Plugin


## Third-Party Javascript / CSS Components included as YARN packages

The following packages are not distributed as part of the project's source code. They are defined as packages for 
installation by the YARN package manager. Each pacakage my have its own dependencies, which are not tracked in this document.

Since the YARN installed packaged are not directly distributed alongside the project's source code, this information 
is provided as a high level view of the packages the project depends on, rather than a statement of the packages being distributed.

### Handlebars

Source: https://github.com/handlebars-lang/handlebars.js

Version: 4.7.6

License: MIT


### Bootstrap datepicker

Source: https://github.com/uxsolutions/bootstrap-datepicker

Version: 1.9.0

License: Apache License v2.0


### Chart.js

Source: https://github.com/chartjs

Version: 2.9.4

License: MIT


### bootstrap-wysiwyg

Source: https://github.com/consected/bootstrap-wysiwyg (forked from https://github.com/steveathon/bootstrap-wysiwyg)

Version: 2.0.2

License: MIT

Notes: patched version 2.0.1 from forked repository to include specific project requirements in the use of 
multiple active editors, and to control a clean repository version.


### jQuery Hotkeys

Source: https://github.com/consected/jquery.hotkeys (forked unchanged from https://github.com/jeresig/jquery.hotkeys)

Version: unversioned

License: not specified

Notes: YARN install uses fork to ensure a known version from https://github.com/consected/jquery.hotkeys

Exclusively used by bootstrap-wysiwyg


### Moment

Source: https://github.com/moment/moment/

Version: 2.29.1

License: MIT


### Typeahead.js

Source: https://github.com/twitter/typeahead.js

Version: 0.11.1

License: MIT


### jQuery Timepicker

Source: https://github.com/wvega/timepicker

Version: 1.3.3

License: Dual licensed - MIT and GPL. For this project, MIT is selected


### Textarea-Autogrow

Source: https://github.com/evyros/textarea-autogrow

Version: 1.0.0

License: MIT


### JS-YAML

Source: https://github.com/nodeca/js-yaml

Version: 3.14.0

License: MIT


### megamark

Source: https://github.com/bevacqua/megamark

Version: 3.3.0

License: MIT


### domador

Source: https://github.com/bevacqua/domador

Version: 2.4.4

License: MIT

Location: app/assets/*/app/


### jQuery ScrollTo

Source: https://github.com/flesler/jquery.scrollTo

Version: 2.1.2

License: MIT


### Chosen

Source: https://github.com/harvesthq/chosen

Version: 1.7.0

License: MIT



### Tablesorter (FORK)

Source: https://github.com/Mottie/tablesorter

Version: 2.31.3

License: Dual licensed - MIT and GPL. For this project, MIT is selected


### FullCalendar

Source: https://github.com/fullcalendar/fullcalendar

Version: 4.2.0

License: MIT


### jQuery Mask Plugin

Source: https://github.com/consected/jQuery-Mask-Plugin (forked from https://github.com/igorescobar/jQuery-Mask-Plugin)

Version: 1.14.13

License: MIT

Notes: Includes important caret positioning fixes from the original 1.14.12 that were not incorporated upstream.


### CodeMirror

Source: https://github.com/codemirror/codemirror

Version: 5.58.2

License: MIT

Notes: 

Only a subset of components have been added.


##  For the NFS Store file management uploader - YARN Installed

The following packages are not distributed as part of the project's source code. They are defined as packages for 
installation by the YARN package manager. Each pacakage my have its own dependencies, which are not tracked in this document.

Since the YARN installed packaged are not directly distributed alongside the project's source code, this information 
is provided as a high level view of the packages the project depends on, rather than a statement of the packages being distributed.


### jQuery File Upload Plugin

Source: https://github.com/blueimp/jQuery-File-Upload

Version: 9.27.0

License: MIT


### spark-md5

Source: https://github.com/satazor/js-spark-md5

Version: 3.0.1

License: Dual licensed - WTF2 and MIT. For this distribution, MIT is selected

