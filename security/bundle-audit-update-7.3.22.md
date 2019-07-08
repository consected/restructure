Updating ruby-advisory-db ...
Updating 41812d7..f39d4a5
Fast-forward
 gems/chloride/CVE-2018-6517.yml                    |   17 +++++++++++++
 gems/delayed_job_web/CVE-2017-12097.yml            |   17 +++++++++++++
 gems/fat_free_crm/CVE-2018-1000842.yml             |   23 ++++++++++++++++++
 gems/mail/{OSVDB-131677.yml => CVE-2015-9097.yml}  |    0
 gems/omniauth-saml/CVE-2017-11430.yml              |   17 +++++++++++++
 gems/omniauth/CVE-2015-9284.yml                    |   25 ++++++++++++++++++++
 gems/openssl/CVE-2016-7798.yml                     |   16 ++++++++++++
 gems/ox/CVE-2017-15928.yml                         |   16 ++++++++++++
 gems/ox/CVE-2017-16229.yml                         |   16 ++++++++++++
 gems/rack-protection/CVE-2018-1000119.yml          |   18 ++++++++++++++
 gems/radiant/CVE-2018-5216.yml                     |   12 +++++++++
 gems/radiant/CVE-2018-7261.yml                     |   13 ++++++++++
 gems/rails_admin/CVE-2017-12098.yml                |   22 +++++++++++++++++
 gems/rest-client/CVE-2015-3448.yml                 |   15 ++++++++++++
 .../rubygems-update}/CVE-2013-4287.yml             |    1 +
 .../rubygems-update}/CVE-2013-4363.yml             |    1 +
 .../rubygems-update}/CVE-2015-3900.yml             |    1 +
 .../rubygems-update}/CVE-2015-4020.yml             |    1 +
 .../rubygems-update}/CVE-2017-0899.yml             |    1 +
 .../rubygems-update}/CVE-2017-0900.yml             |    1 +
 .../rubygems-update}/CVE-2017-0901.yml             |    1 +
 .../rubygems-update}/CVE-2017-0902.yml             |    1 +
 .../rubygems-update}/CVE-2017-0903.yml             |    1 +
 .../rubygems-update}/CVE-2019-8320.yml             |    1 +
 .../rubygems-update}/CVE-2019-8321.yml             |    1 +
 .../rubygems-update}/CVE-2019-8322.yml             |    1 +
 .../rubygems-update}/CVE-2019-8323.yml             |    1 +
 .../rubygems-update}/CVE-2019-8324.yml             |    1 +
 .../rubygems-update}/CVE-2019-8325.yml             |    1 +
 .../rubygems-update}/OSVDB-33561.yml               |    1 +
 .../rubygems-update}/OSVDB-81444.yml               |    1 +
 .../rubygems-update}/OSVDB-85809.yml               |    1 +
 gems/sinatra/CVE-2018-7212.yml                     |   19 +++++++++++++++
 gems/smart_proxy_dynflow/CVE-2018-14643.yml        |   18 ++++++++++++++
 gems/strong_password/CVE-2019-13354.yml            |   16 ++++++++++++
 lib/github_advisory_sync.rb                        |   17 ++++--------
 libraries/rubygems                                 |    1 +
 37 files changed, 305 insertions(+), 11 deletions(-)
 create mode 100644 gems/chloride/CVE-2018-6517.yml
 create mode 100644 gems/delayed_job_web/CVE-2017-12097.yml
 create mode 100644 gems/fat_free_crm/CVE-2018-1000842.yml
 rename gems/mail/{OSVDB-131677.yml => CVE-2015-9097.yml} (100%)
 create mode 100644 gems/omniauth-saml/CVE-2017-11430.yml
 create mode 100644 gems/omniauth/CVE-2015-9284.yml
 create mode 100644 gems/openssl/CVE-2016-7798.yml
 create mode 100644 gems/ox/CVE-2017-15928.yml
 create mode 100644 gems/ox/CVE-2017-16229.yml
 create mode 100644 gems/rack-protection/CVE-2018-1000119.yml
 create mode 100644 gems/radiant/CVE-2018-5216.yml
 create mode 100644 gems/radiant/CVE-2018-7261.yml
 create mode 100644 gems/rails_admin/CVE-2017-12098.yml
 create mode 100644 gems/rest-client/CVE-2015-3448.yml
 rename {libraries/rubygems => gems/rubygems-update}/CVE-2013-4287.yml (96%)
 rename {libraries/rubygems => gems/rubygems-update}/CVE-2013-4363.yml (97%)
 rename {libraries/rubygems => gems/rubygems-update}/CVE-2015-3900.yml (96%)
 rename {libraries/rubygems => gems/rubygems-update}/CVE-2015-4020.yml (97%)
 rename {libraries/rubygems => gems/rubygems-update}/CVE-2017-0899.yml (95%)
 rename {libraries/rubygems => gems/rubygems-update}/CVE-2017-0900.yml (95%)
 rename {libraries/rubygems => gems/rubygems-update}/CVE-2017-0901.yml (95%)
 rename {libraries/rubygems => gems/rubygems-update}/CVE-2017-0902.yml (95%)
 rename {libraries/rubygems => gems/rubygems-update}/CVE-2017-0903.yml (96%)
 rename {libraries/rubygems => gems/rubygems-update}/CVE-2019-8320.yml (97%)
 rename {libraries/rubygems => gems/rubygems-update}/CVE-2019-8321.yml (95%)
 rename {libraries/rubygems => gems/rubygems-update}/CVE-2019-8322.yml (96%)
 rename {libraries/rubygems => gems/rubygems-update}/CVE-2019-8323.yml (96%)
 rename {libraries/rubygems => gems/rubygems-update}/CVE-2019-8324.yml (96%)
 rename {libraries/rubygems => gems/rubygems-update}/CVE-2019-8325.yml (95%)
 rename {libraries/rubygems => gems/rubygems-update}/OSVDB-33561.yml (96%)
 rename {libraries/rubygems => gems/rubygems-update}/OSVDB-81444.yml (95%)
 rename {libraries/rubygems => gems/rubygems-update}/OSVDB-85809.yml (95%)
 create mode 100644 gems/sinatra/CVE-2018-7212.yml
 create mode 100644 gems/smart_proxy_dynflow/CVE-2018-14643.yml
 create mode 100644 gems/strong_password/CVE-2019-13354.yml
 create mode 120000 libraries/rubygems
Updated ruby-advisory-db
ruby-advisory-db: 381 advisories
