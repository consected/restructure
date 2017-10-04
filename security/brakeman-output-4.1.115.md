# BRAKEMAN REPORT

| Application path        | Rails version | Brakeman version | Started at                | Duration            |
|-------------------------|---------------|------------------|---------------------------|---------------------|
| /var/opt/passenger/fphs | 4.2.9         | 3.7.0            | 2017-10-04 06:17:02 -0400 | 4.221850004 seconds |

| Checks performed                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| BasicAuth, BasicAuthTimingAttack, ContentTag, CreateWith, CrossSiteScripting, DefaultRoutes, Deserialize, DetailedExceptions, DigestDoS, DynamicFinders, EscapeFunction, Evaluation, Execute, FileAccess, FileDisclosure, FilterSkipping, ForgerySetting, HeaderDoS, I18nXSS, JRubyXML, JSONEncoding, JSONParsing, LinkTo, LinkToHref, MailTo, MassAssignment, MimeTypeDoS, ModelAttrAccessible, ModelAttributes, ModelSerialize, NestedAttributes, NestedAttributesBypass, NumberToCurrency, QuoteTableName, Redirect, RegexDoS, Render, RenderDoS, RenderInline, ResponseSplitting, RouteDoS, SQL, SQLCVEs, SSLVerify, SafeBufferManipulation, SanitizeMethods, SelectTag, SelectVulnerability, Send, SendFile, SessionManipulation, SessionSettings, SimpleFormat, SingleQuotes, SkipBeforeFilter, StripTags, SymbolDoSCVE, TranslateBug, UnsafeReflection, ValidationRegex, WithoutProtection, XMLDoS, YAMLParsing |

### SUMMARY

| Scanned/Reported  | Total |
|-------------------|-------|
| Controllers       | 28    |
| Models            | 30    |
| Templates         | 83    |
| Errors            | 0     |
| Security Warnings | 9 (3) |

| Warning Type          | Total |
|-----------------------|-------|
| Cross Site Scripting  | 4     |
| Redirect              | 1     |
| Remote Code Execution | 3     |
| SQL Injection         | 1     |

### SECURITY WARNINGS

| Confidence | Class               | Method          | Warning Type                                                                                  | Message                                                                                                                                                                                                |
|------------|---------------------|-----------------|-----------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| High       | MastersController   | create          | [Redirect](http://brakemanscanner.org/docs/warning_types/redirect/)                           | Possible unprotected redirect near line 81: `redirect_to(Master.create_master_records(current_user), :notice => ("Created Master Record with MSID #{Master.create_master_records(current_user).id}"))` |
| Medium     | ReportsController   | show            | [Cross Site Scripting](http://brakemanscanner.org/docs/warning_types/cross_site_scripting/)   | Unescaped model attribute rendered inline near line 67: `render(text => "Generated SQL invalid.\n#{Report.find(params[:id].to_i).clean_sql}\n#{$!.to_s}", { :status => 400 })`                         |
| Medium     | ItemFlagsController | set_parent_item | [Remote Code Execution](http://brakemanscanner.org/docs/warning_types/remote_code_execution/) | Unsafe reflection method constantize called with model attribute near line 68: `ItemFlag.works_with(params[:item_controller].singularize.camelize).constantize`                                        |
| Medium     | ItemFlagsController | set_parent_item | [Remote Code Execution](http://brakemanscanner.org/docs/warning_types/remote_code_execution/) | Unsafe reflection method constantize called with model attribute near line 70: `ItemFlag.works_with(params[:item_controller].singularize.camelize).constantize`                                        |
| Medium     | ItemFlagsController | set_parent_item | [Remote Code Execution](http://brakemanscanner.org/docs/warning_types/remote_code_execution/) | Unsafe reflection method constantize called with model attribute near line 72: `"DynamicModel::#{ItemFlag.works_with(params[:item_controller].singularize.camelize)}".constantize`                     |
| Medium     | Protocol            | updates         | [SQL Injection](http://brakemanscanner.org/docs/warning_types/sql_injection/)                 | Possible SQL injection near line 11: `where("name = '#{"Updates".freeze}' AND (disabled IS NULL OR disabled = FALSE)")`                                                                                |

### View Warnings:

| Confidence | Template                                 | Warning Type                                                                               | Message                                                                                                          |
|------------|------------------------------------------|--------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------|
| High       | reports/_form (ReportsController#show)   | [Cross Site Scripting](http://brakemanscanner.org/docs/warning_types/cross_site_scripting) | Unescaped model attribute near line 2: `Report.find(params[:id].to_i).description.gsub("\n", "<br />")`          |
| High       | reports/_results (Template:reports/show) | [Cross Site Scripting](http://brakemanscanner.org/docs/warning_types/cross_site_scripting) | Unescaped model attribute near line 13: `Report.find(params[:id].to_i).clean_sql`                                |
| Weak       | reports/show (ReportsController#show)    | [Cross Site Scripting](http://brakemanscanner.org/docs/warning_types/cross_site_scripting) | Unescaped model attribute near line 21: `(Report.find(params[:id].to_i).description or "").gsub("\n", "<br />")` |

