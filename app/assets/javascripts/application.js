// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery3
//= require jquery_ujs
//= require bootstrap
//= require app/nfs_store/application
//= require app/secure_view/secure_view

// YARN installed packages
// Distribution files referenced directly to allow asset pipeline to handle compilation and loading
//= require handlebars/dist/handlebars
//= require bootstrap-datepicker/dist/js/bootstrap-datepicker
//= require chart.js/dist/chart
//= require bootstrap-wysiwyg/src/bootstrap-wysiwyg
//= require jquery.hotkeys/jquery.hotkeys
// Note: moment is required with the min file to avoid the need to transcompile
//= require moment/min/moment-with-locales.min
//= require luxon/build/global/luxon
//= require chartjs-adapter-luxon/dist/chartjs-adapter-luxon.umd.js
//= require typeahead.js/dist/typeahead.bundle.js
//= require jquery-timepicker/jquery.timepicker
//= require textarea-autogrow/textarea-autogrow
//= require megamark/dist/megamark
//= require domador/dist/domador
//= require jquery.scrollto/jquery.scrollTo
//= require chosen-js/chosen.jquery
//= require tablesorter/dist/js/jquery.tablesorter
//= require jquery-mask-plugin/dist/jquery.mask
//= require jsTreeTable/treeTable.js
// Note FullCalendar is frozen at 4.2.0 to avoid needing to transcompile
//= require @fullcalendar/core/main
//= require @fullcalendar/interaction/main
//= require @fullcalendar/daygrid/main
//= require @fullcalendar/timegrid/main
// nfs_store dependencies - blueimp-file-upload frozen at 9.27 pending testing of later versions
//= require blueimp-file-upload/js/vendor/jquery.ui.widget.js
//= require blueimp-file-upload/js/jquery.iframe-transport.js
//= require blueimp-file-upload/js/jquery.fileupload.js
// For nfs_store MD5 support
//= require spark-md5/spark-md5

//= require highlightjs/highlight.pack.js
//= require ./big_select/big_select.js
//= require js-yaml/dist/js-yaml 

//= require_tree ./app
