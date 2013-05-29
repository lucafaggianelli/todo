What
====

*TODO* is a tasks-list management tool for Linux. You can use it for
anything, from shopping list to birthdays remainder, anyway has been
thought for dealing with 'to do' tasks in programming.

Tasks are stored in text format, so anyone can read and write the list.
Take a look at the
[`todo`](https://github.com/lucafaggianelli/todo/blob/master/todo) file:
the *TODO* list for this project.


Getting started
===============

Obtain the code by downloading the zip or better by cloning it with git
```
git clone https://github.com/lucafaggianelli/todo.git
```
Now it should run with
```
cd todo
./todo.sh

# Additionally you may need to allow execution
chmod +x todo.sh
```
Now you can choose of adding the folder to the `$PATH` var, which I don't
recommend. Maybe make a link of `todo.sh` into a directory already in
`$PATH`
```
echo $PATH
# /usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin
ln -s ./todo.sh /usr/bin/todo
```
I personally use the alias method
```
# /home/luca/programming/todo/ is the cloned git folder
# Now you can call the script from anywhere with 't' or whatever
alias t='~/programming/todo/todo.sh'

# Put the above command in your bashrc or whatever and source it!
nano ~/.bashrc
source ~/.bashrc
```

Usage
=====

Many *TODO* commands resemble *famous* ones, so you don't need to
learn/remember anything: rm, ls, mv, / (to search and filter), sort, ...

Although the command are issued in a not-common way, which I think is more
natural in this context. In a Unix shell you use something like:
```
$ script [--some-opts] <command> <target>
```
While here you have (`todo.sh` is aliased to `t`):
```
t [ID|Category] [-some-opts] [command] [-some-opts] [some arguments]
```
In my mind, first of all I think about a *TODO* and then I apply a status
or a priority to it, or issue any command.

Notice that the command is optional, as many times you don't need it! The
*TODO* tool is smart and configurable enough to understand what you want!
(Yet `todo.sh` is aliased to `t`)
```
# List all the TODOs of all category but the ones marked as done [x]
t filter ^x
t / ^x
t ^x
t

# Mark a TODO, that is, mark its status
t 14 mark x
t 14 m x
t 14 x

# Set priority
t 6 priority !
t 6 p !
t 6 !

# Create TODO in category 'Core' with priority ! and status ?
# t <category> [x|?] [!|H|L] <TODO body>
t add Core ! ? Fix that bug
t a Core ! ? Fix that bug
t Core ! ? Fix that bug

# List TODO of the category 'Core'
t ls Core
t Core

# Search free text through all the TODOs showing only ! priority TODOs
t filter anything !
t / anything !
t anything !
```



TODO format
-----------

The *TODO* list can be easily edited by hand following its format:

<pre style="line-height:14px;">
             ┌ Category name
        ─────┴──
        Category
        ========  ├──── Underline
Blank ┤
        456 [x] (H) Need some beer!             ├── Dont align in the file,
        1234 [?] (!) Damn, out of toilet paper!     is done by the tool
        ─┬── ─┬─ ─┬─ ────────────┬─────────────
     UUID┘    │   │              └ Your TODO task here
              │   ├ (!) Critic
  [x] Done    ┤   ├ (H) High
  [?] Pending ┤   ├ (L) Low
  [ ] Open    ┘   └ ( ) No
</pre>


Features
========

Why text?
---------

It is a Command Line Interface tool that uses text files for maximum
interoperability. Using XML or other formats, would allow more features,
easier parsing, etc., but it would be unreadable for humans! Using
formatted text the list is easily sharable, readable, writable also by
people not using this tool.
Moreover, thanks to this features, it is easily extendable with GUI and
remote web apps.


Categories
----------

Each list is divided in categories and *TODO* tasks belong to them.

*TODO* works in a per-directory fashion: it uses the file `todo` in each
folder, so that each project has its own *TODO* list. Moreover is smart
enough touse only one unique list for all project subfolders.


x ? ! H L
---------

Each *TODO* task has a *status* (to do, pending [?], done [x]) to help you
track the status of your work. Pending is useful to remember what you were
working on! *TODO* tasks have also a priority level (low (L), high (H),
critical/bug (!)) to help you decide what is the most important issue to
solve first!


Commit
------

The tool features a powerful command, *commit*, which acts as an export or
archive function. It moves all the *TODO* tasks marked as _done_ from the
list file `todo` to the `changelog` file, so you can work on a clean tasks
list and have a detailed changelog. This command becomes more powerful when
run after a git commit (triggered by hooks) so the new release of your
software include the changelog.


Motivations
===========

Why do I/you need such a tool? Moreover it's plenty of TODOs tools, why
building a new one?
<dl>

<dt>Memory</dt>
<dd>When programming, I find bugs to fix, new features to add etc.,
    but if I don't write somewhere/somehow what to do, the day after I'll
    forget most of them and I'll spend a lot of time to resume!</dd>


<dt>Work status</dt>
<dd>The ability to mark priority (high, low) and status (done,
    pending) allows me to quickly decide which is the most important issue
    to solve and to remember on what I was working the last time.</dd>

<dt>Detailed changelog</dt>
<dd>I like to have detailed log of all changes. I use
    git for development and sure the commit message is a great changelog,
    but if you directly include all the *TODO* tasks marked as done at the
    time of commit it's better.</dd>
</dl>


Development
===========

If you're interested in the project, you're more than welcome to suggest
new features and alert me for bugs, installation problems.

It would be great to have some feedback on compatibiliy (does it run on Mac
?). I mainly use `sed`, but some other command may be not available on some
machine...please tell me!

If you would like to write some code, you're again more than welcome! Check
the documentation and ask me any question about. About the things to do
...well you know where you can find the list! Also it would be a good
occasion to build a *collaborative* mode with *TODO*s authorship and
timestamps.

Here what is useful at the moment:

* GUI frontend, maybe web
* Multiuser collaborative mode
* Porting or better binding to new languages
