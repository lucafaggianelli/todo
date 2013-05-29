What
====

*TODO* is a tasks-list management tool. You can use it for anything, from
shopping list to birthdays remainder, anyway has been thought for dealing
with 'to do' tasks in programming.

Tasks are stored in text format, so you can read and write the list by hand.
Take a look at the `todo` file: it is the *TODO* list for this project.


Features
========

It is a Command Line Interface tool that uses text files for maximum
interoperability. Using XML or other formats, would allow more features,
easier parsing, etc., but it would be unreadable for humans! Using
formatted text the list is easily sharable, readable, writable also by people
not using this tool.
Moreover, thanks to this features, it is easily extendable with GUI and
remote web apps.

It works in a per-directory fashion: it uses the file `todo` in each folder,
so that each project has its own *TODO* list. Moreover is smart enough to
use only one unique list for all project subfolders.

Each *TODO* task has a *status* (to do, pending, done) to help you track
the status of your work. Pending is useful to remember what you were working
on! *TODO* tasks have also a priority level (low, high, critical/bug) to
help you decide what is the most important issue to solve first!

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

1.  _Memory_. When programming, I find bugs to fix, new features to add etc.,
    but if I don't write somewhere/somehow what to do, the day after I'll
    forget most of them and I'll spend a lot of time to resume!

2.  _Work status_. The ability to mark priority (high, low) and status (done,
    pending) allows me to quickly decide which is the most important issue
    to solve and to remember on what I was working the last time.

3.  _Detailed changelog_. I like to have detailed log of all changes. I use
    git for development and sure the commit message is a great changelog,
    but if you directly include all the *TODO* tasks marked as done at the
    time of commit it's better.
