# BRAKEMAN REPORT

| Application path                       | Rails version | Brakeman version | Started at                | Duration            |
|----------------------------------------|---------------|------------------|---------------------------|---------------------|
| /home/phil/NetBeansProjects/fpa-phase2 | 4.2.2         | 3.1.2            | 2015-11-12 15:04:50 -0500 | 2.992426738 seconds |

| Checks performed                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| BasicAuth, ContentTag, CreateWith, CrossSiteScripting, DefaultRoutes, Deserialize, DetailedExceptions, DigestDoS, EscapeFunction, Evaluation, Execute, FileAccess, FileDisclosure, FilterSkipping, ForgerySetting, HeaderDoS, I18nXSS, JRubyXML, JSONEncoding, JSONParsing, LinkTo, LinkToHref, MailTo, MassAssignment, ModelAttrAccessible, ModelAttributes, ModelSerialize, NestedAttributes, NumberToCurrency, QuoteTableName, Redirect, RegexDoS, Render, RenderDoS, RenderInline, ResponseSplitting, SQL, SQLCVEs, SSLVerify, SafeBufferManipulation, SanitizeMethods, SelectTag, SelectVulnerability, Send, SendFile, SessionManipulation, SessionSettings, SimpleFormat, SingleQuotes, SkipBeforeFilter, StripTags, SymbolDoSCVE, TranslateBug, UnsafeReflection, ValidationRegex, WithoutProtection, XMLDoS, YAMLParsing |

### SUMMARY

| Scanned/Reported  | Total |
|-------------------|-------|
| Controllers       | 28    |
| Models            | 29    |
| Templates         | 81    |
| Errors            | 0     |
| Security Warnings | 9 (4) |

| Warning Type          | Total |
|-----------------------|-------|
| Cross Site Scripting  | 4     |
| Redirect              | 1     |
| Remote Code Execution | 3     |
| SQL Injection         | 1     |

### SECURITY WARNINGS

| Confidence | Class               | Method                  | Warning Type                                                                                  | Message                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
|------------|---------------------|-------------------------|-----------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| High       | MastersController   | create                  | [Redirect](http://brakemanscanner.org/docs/warning_types/redirect/)                           | Possible unprotected redirect near line 79: `redirect_to(Master.create_master_records(current_user), :notice => ("Created Master Record with MSID #{Master.create_master_records(current_user).id}"))`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| High       | Master              | Master.search_on_params | [SQL Injection](http://brakemanscanner.org/docs/warning_types/sql_injection/)                 | Possible SQL injection near line 256: `Master.select(["masters.id", "masters.pro_info_id", "masters.pro_id", "masters.msid", "masters.rank as master_rank"]).joins((([alt_condition_attrib[:joins], alt_condition_attrib[:joins]] + alt_condition_attrib[:joins]) << params_key.to_s.gsub("_attributes", "").to_sym)).uniq.where(((Master.reflect_on_association(params_key.to_s.gsub("_attributes", "").to_sym).klass.table_name or Master.reflect_on_association(params_key.to_s.gsub("_attributes", "").to_sym).plural_name.to_s) or params_key.to_s.pluralize) => (params_val.first.last.select do  (not v1.nil?) and (not alt_condition(params_key.to_s.gsub("_attributes", "").to_sym, [key1, v1]))  end), params_key => params_val.first.last)` |
| Medium     | ReportsController   | show                    | [Cross Site Scripting](http://brakemanscanner.org/docs/warning_types/cross_site_scripting/)   | Unescaped model attribute rendered inline near line 62: `render(text => "Generated SQL invalid.\n#{Report.find(params[:id].to_i).clean_sql}\n#{$!.to_s}", { :status => 400 })`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| Medium     | ItemFlagsController | set_parent_item         | [Remote Code Execution](http://brakemanscanner.org/docs/warning_types/remote_code_execution/) | Unsafe reflection method constantize called with model attribute near line 61: `ItemFlag.works_with(params[:item_controller].singularize.camelize).constantize`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| Medium     | ItemFlagsController | set_parent_item         | [Remote Code Execution](http://brakemanscanner.org/docs/warning_types/remote_code_execution/) | Unsafe reflection method constantize called with model attribute near line 63: `ItemFlag.works_with(params[:item_controller].singularize.camelize).constantize`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| Medium     | ItemFlagsController | set_parent_item         | [Remote Code Execution](http://brakemanscanner.org/docs/warning_types/remote_code_execution/) | Unsafe reflection method constantize called with model attribute near line 65: `"DynamicModel::#{ItemFlag.works_with(params[:item_controller].singularize.camelize)}".constantize`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |

### View Warnings:

| Confidence | Template                                 | Warning Type                                                                               | Message                                                                                                          |
|------------|------------------------------------------|--------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------|
| High       | reports/_form (ReportsController#show)   | [Cross Site Scripting](http://brakemanscanner.org/docs/warning_types/cross_site_scripting) | Unescaped model attribute near line 2: `Report.find(params[:id].to_i).description.gsub("\n", "<br />")`          |
| High       | reports/_results (Template:reports/show) | [Cross Site Scripting](http://brakemanscanner.org/docs/warning_types/cross_site_scripting) | Unescaped model attribute near line 11: `Report.find(params[:id].to_i).clean_sql`                                |
| Weak       | reports/show (ReportsController#show)    | [Cross Site Scripting](http://brakemanscanner.org/docs/warning_types/cross_site_scripting) | Unescaped model attribute near line 10: `(Report.find(params[:id].to_i).description or "").gsub("\n", "<br />")` |
