# BRAKEMAN REPORT

| Application path                 | Rails version | Brakeman version | Started at                | Duration            |
|----------------------------------|---------------|------------------|---------------------------|---------------------|
| /home/phil/NetBeansProjects/fpa1 | 4.2.2         | 3.0.5            | 2015-09-17 10:59:56 -0400 | 2.078145617 seconds |

| Checks performed                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| BasicAuth, ContentTag, CreateWith, CrossSiteScripting, DefaultRoutes, Deserialize, DetailedExceptions, DigestDoS, EscapeFunction, Evaluation, Execute, FileAccess, FileDisclosure, FilterSkipping, ForgerySetting, HeaderDoS, I18nXSS, JRubyXML, JSONEncoding, JSONParsing, LinkTo, LinkToHref, MailTo, MassAssignment, ModelAttrAccessible, ModelAttributes, ModelSerialize, NestedAttributes, NumberToCurrency, QuoteTableName, Redirect, RegexDoS, Render, RenderDoS, RenderInline, ResponseSplitting, SQL, SQLCVEs, SSLVerify, SafeBufferManipulation, SanitizeMethods, SelectTag, SelectVulnerability, Send, SendFile, SessionSettings, SimpleFormat, SingleQuotes, SkipBeforeFilter, StripTags, SymbolDoSCVE, TranslateBug, UnsafeReflection, ValidationRegex, WithoutProtection, XMLDoS, YAMLParsing |

### SUMMARY

| Scanned/Reported  | Total |
|-------------------|-------|
| Controllers       | 21    |
| Models            | 23    |
| Templates         | 52    |
| Errors            | 0     |
| Security Warnings | 3 (3) |

| Warning Type          | Total |
|-----------------------|-------|
| Redirect              | 1     |
| Remote Code Execution | 2     |

### SECURITY WARNINGS

| Confidence | Class                 | Method          | Warning Type                                                                                  | Message                                                                                                                                                                                                 |
|------------|-----------------------|-----------------|-----------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| High       | MastersController     | create          | [Redirect](http://brakemanscanner.org/docs/warning_types/redirect/)                           | Possible unprotected redirect near line 152: `redirect_to(Master.create_master_records(current_user), :notice => ("Created Master Record with MSID #{Master.create_master_records(current_user).id}"))` |
| High       | DefinitionsController | show            | [Remote Code Execution](http://brakemanscanner.org/docs/warning_types/remote_code_execution/) | Unsafe reflection method constantize called with parameter value near line 16: `params[:id].classify.constantize`                                                                                       |
| High       | ItemFlagsController   | set_parent_item | [Remote Code Execution](http://brakemanscanner.org/docs/warning_types/remote_code_execution/) | Unsafe reflection method constantize called with parameter value near line 59: `params[:item_controller].singularize.camelize.constantize`                                                              |

