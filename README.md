# IRIS - Integrated Retrieval and Inventory System
[![Build Status](https://travis-ci.org/ndlib/annex-ims.svg?branch=master)](https://travis-ci.org/ndlib/annex-ims)
[![Coverage Status](https://coveralls.io/repos/ndlib/annex-ims/badge.svg)](https://coveralls.io/r/ndlib/annex-ims)
[![Code Climate](https://codeclimate.com/github/ndlib/annex-ims/badges/gpa.svg)](https://codeclimate.com/github/ndlib/annex-ims)

IRIS - Integrated Retrieval and Inventory System for offsite storage facilities

## Getting Started:

Requirements:

* Ruby (~> 2.6.6)
* RabbitMQ (~> 3.5.0) - https://www.rabbitmq.com/download.html
* Postgres - (~> 9.4) - http://www.postgresql.org/download/

Installation:

On Mac, install Qt@5.5 following directions here: https://github.com/thoughtbot/capybara-webkit/wiki/Installing-Qt-and-compiling-capybara-webkit#homebrew

Also on Mac, near the top of .bashrc (or similar), add `export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES` - see https://blog.phusion.nl/2017/10/13/why-ruby-app-servers-break-on-macos-high-sierra-and-what-can-be-done-about-it/

```console
$ bundle install
$ bundle exec rake db:create db:migrate db:seed
```

You should also add your local computer's name to /etc/hosts in order to check email links

Start thin; This will fire up the application. Sneakers and Postgres should also be running. The second line below is only necessary on certain Mac operating systems.

```console
$ brew services restart postgresql
$ export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES
$ bundle exec thin start -C config/thin.yml
$ brew services start rabbitmq
$ bundle exec rake sneakers:start
```
*NOTE*: On Mac OS systems running High Sierra and above, you may run into an issue running thin. Thin will fork processes internally, and Apple has implemented a safety feature that doesn't allow the type of forking that thin (or Puma or a host of other Rails containers) uses so you may need to issues this as an ENV to your shell before running thin:

```console
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES
```

*BUT...*: This is not, in general, recommended. Your mileage may vary.

## Chron tasks

The system uses chron to schedule some tasks that are necessary for system operation (e.g. - ensuring that sneakers is running and retrieving open requests from the ILS). The tasks that are configured to run under chron are documented in <app-dir>/config/schedule.rb.

If your core directories are set up correctly, you should be all set.

## Indexing records

The system uses OpenSearch to index records. Given the potentially high volume of records handled by the IMS, this is necessary for performance reasons. In order to initiate a complete reindex of the records, use the following command:

```console
$ export RAILS_ENV=<environment>
$ bundle exec rake (TBD)
```

Please note: depending on the number of records, reindexing the entire database could take significant time and during reindexing certain application functions will not work or operate in a degraded fashion.
