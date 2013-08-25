atpl.vim
========

Version 1.0
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
values. But, we can make this easier if we pre-define that variables. To make
this, we use a global list that the plugin provide, in this way:

    let g:atpl_UsersList['$AUTHOR$'] = 'Author Name'
    let g:atpl_UsersList['$AUTHORMAIL$'] = '<name at domain dot com>'
    let g:atpl_UsersList['$PROJECT$'] = 'Project Name'
    let g:atpl_UsersList['$VERSION$'] = '1.0'
    let g:aptl_UsersList['$OWNER$'] = 'Company Name'

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
variable replacements. It also help us checking for circular references. The
`$BASENAME$` macro is a constant expression (pre-defined) that will evaluate
to the file name, without extension. So if we name our file as `Plugin.cpp`
the class name will be `Plugin` and also the constructor and destructor
skeleton will be ready.

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
searched first. So your templates will override the default ones if you choose
the same file names.

The documentation explains better all the pre-defined variables and the syntax
used inside a template or snippet file, configuration options and default
mappings.

History
-------

* **Jun 5, 2013**: Changes in documentation.
  Typo in internal variables.
  Added support for different character codes.
* **May 24, 2013**: First release.

TODO
----

* Add a command to add/edit a template/snippet file in the current Vim
  instance.
* Better completion list when `<C-D>` is pressed after the `:Template`
  command.
* Improve documentation.
* Include conditional expansion of template pieces.

