atpl.vim
========

Version 2.0
-----------

**atpl** (formely *apptpl* from Apply Template), is a simple script to load
and apply file templates and simple snippets in the current buffer. Its
intention is not build a complete snippet system. For that kind of plugin you
can use [snipMate](https://github.com/msanders/snipmate.vim) or
[UltiSnips](https://github.com/vim-scripts/UltiSnips). They are much more
powerful in this area. The **atpl** plugin is more useful for applying file
templates that are almost ready to go, configured by a set of pre-defined
variables and functions to customize them.

A little example of a `C` source file header in Doxygen style:

    /**
     * \file
     * <|>
     *
     * \author  <{$AUTHOR$}> <{$AUTHORMAIL$}>
     * \date    <{$LOCALDATE$}>
     * \since   <{$PROJECT$}> <{$VERSION$}>
     *
     * \copyright <{$OWNER$}>, <{$YEAR$}>. All rights reserved.
     */

You write this template in a file called `c_header.c` in one directory
searched by the plugin (I will walk through this later). Then you open a new
`C` file in Vim/GVim and type, in the command area:

    :Template c_header.c

When the plugin starts working it will ask you about the variable values that
you put in the template. For our example, it will ask for the values of
`$AUTHOR$`, `$AUTHORMAIL$`, `$PROJECT$`, `$VERSION$` and `$OWNER$`.  The
others values, like `$LOCALDATE$` and `$YEAR$` are pre-defined constants that
evaluate to VimL functions that write (guess) the local date and year. When
the plugin finishes parsing the file it will look for the `<|>` macro and
leave the cursor in that place.

So, every time we use the `:Template` command it will ask us for that variable
values. But, we can make this easier if we predefine that variables. To make
this, we use a global list that the plugin provide, in this way:

    let g:atpl_UsersList['$AUTHOR$'] = 'Author Name'
    let g:atpl_UsersList['$AUTHORMAIL$'] = '<name at domain dot com>'
    let g:atpl_UsersList['$PROJECT$'] = 'Project Name'
    let g:atpl_UsersList['$VERSION$'] = '1.0'
    let g:aptl_UsersList['$OWNER$'] = 'Company Name'

Or, you could write:

    let g:atpl_UsersList = {
      \ '$AUTHOR$': 'Author Name',
      \ '$AUTHORMAIL$': '<address at amil do com>',
      \ '$PROJECT$': 'My Super Duper Project',
      \ '$VERSION$': 'Some Number',
      \ '$OWNER$': 'Company or Personal name'
      \ }

For now on, when we call the template, the plugin will replace all variables
with the pre-defined values. Personally I put `$AUTHOR$` and `$AUTHORMAIL$` in
my `.vimrc` file. The others variables I put in scripts loaded for the project
that I am working on.

The plugin is very flexible so we can reuse templates that are already
defined. For example, we can create a template for a `C++` class and reuse
that `c_header` template made before. The file would look like this:


    <{<c_header.c>}>
    #include "<{$BASENAME$}>.h"

    /**
     * 
     */
    class <{$BASENAME$}>
    {
        // CONSTRUCTOR / DESTRUCTOR
        <{$BASENAME$}>() { }
        ~<{$BASENAME$}>() { }
    }


The instruction in the first line (`<{<c_header.c>}>`) will include the
`c_header.c` file. The plugin includes the file before doing any parsing and
variable replacements. It also checks for circular references. The `$BASENAME$`
macro is a constant expression (pre-defined) that will evaluate to the file
name, without extension. So if we name our file as `Plugin.cpp` the class name
will be `Plugin` and also the constructor and destructor skeleton will be
ready.

Search Paths
------------

The plugin already has a set of file templates distributed in the `atpl`
directory. You can set your own list in the same directory or in any other
directory that you choose. There is a global variable with the
directories the plugin will search for templates.

    let g:atpl_TemplatePath = '$VIM/atpl'

That is the default configuration. You can use environment variables at your
will. The expansion is made by the plugin as needed. You can customize that by
putting your own template directory in the list. Lets say:

    let g:atpl_TemplatePath .= ',$HOME/templates'

So, now, the list is `$VIM/atpl,$HOME/templates`. The plugin will search for
template names in backward order. That means the last directory will be
searched first. Template files can have same name, which is found first will be used.

The documentation explains better all the predefined variables and the syntax
used inside a template or snippet file, configuration options and default
mappings.

New Template Format
-------------------

In this revision the template file format was changed to allow a simplified configuration.
Also, we introduced control flow statements that allows for parts of the templates to be
hidden depending on conditional statements.

Since this change breaks backward compatibility we have to introduce a new way of defining
macros and variables so the old Templates can leave together with the new ones and still
work.

In the new template format each macro must will be in a single line. Macros that are broken
in multiple lines will be ignored and written as is in the final output file. Therefore, a
macro in the new template format must be enclosed in a set of two square
brackets line this:

    [[this is a macro]]

Inside a macro you can have any number of variables. Variables are identifiers
that have values defined in the `g:atpl_UsersList` Dictionary like the
previous version. Unlike the previous version the variables now don't need to
be enclosed with '@' nor '$' signs. But it still need to start with a '$'
sign:

    [[This is a macro with $one and $two variables.]]

Somewhere you will define in this set of variables. Notice the lack of '$' sign in the variable
definition. It is used only in the replacement macro to identify it as a variable name.

    let g:atpl_UsersList = { 'one': 'first', 'two': 'second' }

The above example will lead to the following line in the output file:

    This is a macro with first and second variables

Sometimes you will need to have a variable that expands to a calculated value at the time
of its expansion. In the old version this kind of variable should start and end with a '$'
sign. In this new version the variable must start with two '$'.

    [[This is a substitution line expanded at $$date]]

Then define '$$date' as:

    let g:atpl_UsersList = { 'date': 'strftime("%Y, %m %d")' }

Which will output following line. The `strftime()` function will be expanded
in the moment of the replacement and will have the day, month and year of that
moment.

    This is a substitution line expanded at 2018, April 27

### Control Flow

Control flow is a special kind of replacement line that can be used to output
parts of the template file depending on some conditions. Control flow lines
must be enclosed into two curly braces and the first character must be a '#'
sign. It can have any number of variables and functions that will be evaluated
at the time of the expansion. The control flow replacement line establishes a
block, and must be properly defined. The current supported control flow
statements are:

    [[#if ...:]]
    [[#elseif ...:]]
    [[#else:]]
    [[#endif;]]

Each `[[#if ...:]]` line must have a match `[[#endif;]]` line. Blocks can
nest. The `[[#elseif ...:]]` and `[[#else:]]` lines are optional. For example,
suppose you need to hide some part of a template if we read the end of a
predefined year. You could write this condition as:

    [[#if $$year < $limit:]]
    This will be written only before we reach the limit.
    [[#endif;]]

In the example above, `$$year` is a replacement variable that will expand to
the current year number. It is defined as `strftime("%Y")`. The `$limit`
variable is a constant value defined as `2019`. So while the year is before
2019 the lines in between `[[#if ...:]]` and `[[#endif;]]` will be written in
the output file. As soon as we reach 2019, the line will be suppressed and
nothing will be written. Not even a blank line.

Another example:

    [[#if $$year < $limit || $$year > $limit:]]
      [[#if $$year < $limit:]]
    Line visible before established limit.
      [[#elseif $year > $limit:]]
    Line visible after established limit.
      [[#endif;]]
    [[#else:]]
    Line available in between the established limit.
    [[#endif;]]

You can use any operator that is recognized by Vim in the `[[#if ...:]]` and
`[[#elseif ...:]]` lines. We applied some indentation in the above example to
better identify the blocks. This is not needed. Also, the lines of the
template that will be written in the output file will be indented as defined
in the template. The same example could be written like in the following
example and still be perfect valid.

        [[#if $$year < $limit || $$year > $limit:]]
            [[#if $$year < $limit:]]
    Line visible before established limit.
            [[#elseif $year > $limit:]]
    Line visible after established limit.
            [[#endif;]]
        [[#else:]]
    Line available in between the established limit.
        [[#endif;]]

Notice that control flow macros must lie in its own line. Mix this kind of
macro with plain output text doesn't work.

    This line is [[#if $valid:]] valid [[#else:]] invalid [[#endif;]]

To overcome this situation we allow hou to use an special `iif` statement:

    This is [[#iif $valid ? 'a valid' : 'an invalid';]] line.

Since this is a control flow statement and it will be evaluated the text that
should be output in the result must be enclosed in single or double quotes. In
the example above if the `$valid` variable evaluates to **true** the text "a
valid" will be written. If `$valid` evaluates to **false** the text "an
invalid" will be written.

When `$valid` evaluates to *true*:

    This is a valid line.

When `$valid` evaluates to *false*:

    This is an invalid line.

History
-------

- **Oct, 24, 2013**: Found a bug in the order of loading snippets file.

- **Jun 5, 2013**: Changes in documentation.
  Typo in internal variables.
  Added support for different character codes.
- **May 24, 2013**: First release.

TODO
----

* Add a command to add/edit a template/snippet file in the current Vim
  instance.
* Better completion list when `<C-D>` is pressed after the `:Template`
  command.
* Improve documentation.
* Include conditional expansion of template pieces.

<!-- vim:set ft=markdown: -->
