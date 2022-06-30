# Substitutions

Data from activity log and dynamic model records may be substituted into form captions, [message notifications, form dialogs and UI template blocks](../message_templates/0_introduction.md).
Substitutions may also be used in calculated `if:` conditions in dynamic definitions.

Simple substitution uses double curly brackets `\{\{substitution_name\}\}` -

Conditional blocks of text and substitutions use `\{\{#if substitution_name\}\}any text, markup or substitutions\{\{else\}\}alternative block\{\{/if\}\}`
The conditional expression evaluates to true if the value is present (not false, nil or blank) and allows the appropriate block of text, markup and
substitutions to remain in the generated result.
