# Regular Expressions

## Basic Syntax

- `/.../`     Start and end regex delimiters
- `|`     Alternation
- `()`     Grouping

## Escape Sequences

- `\`    Escape following character. Used to escape any of the following metacharacters: (){}[]^$.\|*+?
- `\Q`     Begin literal sequence
- `\E`     End literal sequence

## Position Matching

- `^`     Start of string or start of line in multi-line mode
- `\A`     Start of string
- `$`     End of string or end of line in multi-line mode
- `\Z`     End of string
- `\b`     Word boundary
- `\B`     Not word boundary
- `\<`     Start of word
- `\>`     End of word

## Character Classes

- `\s`     Whitespace
- `\S`     Not whitespace
- `\w`     Word
- `\W`     Not word
- `\d`     Digit
- `\D`     Not digit
- `\x`     Hexade­cimal digit
- `\O`     Octal digit

## Special Characters

- `\n`     Newline
- `\r`     Carriage return
- `\t`     Tab
- `\v`     Vertical tab
- `\f`     Form feed
- `\xxx`     Octal character xxx
- `\xhh`     Hex character hh

## Groups and Ranges

- `.`     Any character except newline (\n)
- `(a|b)`     a or b
- `(…)`     Group
- `(?:…)`     Passive (non-c­apt­uring) group
- `[abc]`     a, b or c
- `[^abc]`     Not a, b or c
- `[a-z]`     Letters from a to z
- `[A-Z]`     Uppercase letters from A to Z
- `[0-9]`     Digits from 0 to 9

> Note: Ranges are inclusive.

## Quantifiers

- `*`     0 or more
- `+`     1 or more
- `?`     0 or 1
- `{3}`     Exactly 3
- `{3,}`     3 or more
- `{3,5}`     3, 4 or 5

> Note: Quantifiers are greedy - they match as many times as possible. Add a ? after the quantifier to make it ungreedy.

## Assertions

- `?=`     Lookahead assertion
- `?!`     Negative lookahead
- `?<=`     Lookbehind assertion
- ``?!=, ?<!``     Negative lookbehind
- `?>`     Once-only subexp­ression
- `?()`     Condition if-then
- `?()|`     Condition if-then-else
- `?#`     Comment
