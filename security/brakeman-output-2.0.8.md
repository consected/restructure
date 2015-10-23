# BRAKEMAN REPORT

| Application path                       | Rails version | Brakeman version | Started at                | Duration           |
|----------------------------------------|---------------|------------------|---------------------------|--------------------|
| /home/phil/NetBeansProjects/fpa-phase2 | 4.2.2         | 3.1.1            | 2015-10-23 10:45:29 -0400 | 3.92755874 seconds |

| Checks performed                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| BasicAuth, ContentTag, CreateWith, CrossSiteScripting, DefaultRoutes, Deserialize, DetailedExceptions, DigestDoS, EscapeFunction, Evaluation, Execute, FileAccess, FileDisclosure, FilterSkipping, ForgerySetting, HeaderDoS, I18nXSS, JRubyXML, JSONEncoding, JSONParsing, LinkTo, LinkToHref, MailTo, MassAssignment, ModelAttrAccessible, ModelAttributes, ModelSerialize, NestedAttributes, NumberToCurrency, QuoteTableName, Redirect, RegexDoS, Render, RenderDoS, RenderInline, ResponseSplitting, SQL, SQLCVEs, SSLVerify, SafeBufferManipulation, SanitizeMethods, SelectTag, SelectVulnerability, Send, SendFile, SessionManipulation, SessionSettings, SimpleFormat, SingleQuotes, SkipBeforeFilter, StripTags, SymbolDoSCVE, TranslateBug, UnsafeReflection, ValidationRegex, WithoutProtection, XMLDoS, YAMLParsing |

### SUMMARY

| Scanned/Reported  | Total |
|-------------------|-------|
| Controllers       | 27    |
| Models            | 27    |
| Templates         | 78    |
| Errors            | 0     |
| Security Warnings | 8 (8) |

| Warning Type          | Total |
|-----------------------|-------|
| Cross Site Scripting  | 3     |
| Redirect              | 1     |
| Remote Code Execution | 4     |

### SECURITY WARNINGS

| Confidence | Class                 | Method          | Warning Type                                                                                  | Message                                                                                                                                                                                                |
|------------|-----------------------|-----------------|-----------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| High       | MastersController     | create          | [Redirect](http://brakemanscanner.org/docs/warning_types/redirect/)                           | Possible unprotected redirect near line 78: `redirect_to(Master.create_master_records(current_user), :notice => ("Created Master Record with MSID #{Master.create_master_records(current_user).id}"))` |
| High       | DefinitionsController | show            | [Remote Code Execution](http://brakemanscanner.org/docs/warning_types/remote_code_execution/) | Unsafe reflection method constantize called with parameter value near line 23: `params[:id].classify.constantize`                                                                                      |
| High       | ItemFlagsController   | set_parent_item | [Remote Code Execution](http://brakemanscanner.org/docs/warning_types/remote_code_execution/) | Unsafe reflection method constantize called with parameter value near line 59: `params[:item_controller].singularize.camelize.constantize`                                                             |
| High       | ItemFlagsController   | set_parent_item | [Remote Code Execution](http://brakemanscanner.org/docs/warning_types/remote_code_execution/) | Unsafe reflection method constantize called with parameter value near line 61: `params[:item_controller].singularize.camelize.constantize`                                                             |
| High       | ItemFlagsController   | set_parent_item | [Remote Code Execution](http://brakemanscanner.org/docs/warning_types/remote_code_execution/) | Unsafe reflection method constantize called with parameter value near line 63: `"DynamicModel::#{params[:item_controller].singularize.camelize}".constantize`                                          |

### View Warnings:

| Confidence | Template                               | Warning Type                                                                               | Message                                                                                                        |
|------------|----------------------------------------|--------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------|
| High       | reports/_form (ReportsController#show) | [Cross Site Scripting](http://brakemanscanner.org/docs/warning_types/cross_site_scripting) | Unescaped model attribute near line 2: `Report.find((params[:id] or 0).to_i).description.gsub("\n", "<br />")` |
| High       | reports/show (ReportsController#show)  | [Cross Site Scripting](http://brakemanscanner.org/docs/warning_types/cross_site_scripting) | Unescaped model attribute near line 6: `Report.find((params[:id] or 0).to_i).description.gsub("\n", "<br />")` |
| High       | reports/show (ReportsController#show)  | [Cross Site Scripting](http://brakemanscanner.org/docs/warning_types/cross_site_scripting) | Unescaped model attribute near line 16: `Report.find((params[:id] or 0).to_i).clean_sql`                       |

