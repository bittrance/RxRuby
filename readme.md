[![Build Status](https://travis-ci.org/bittrance/rxruby.svg?branch=master)](https://travis-ci.org/bittrance/rxruby)
[![Gem Version](https://badge.fury.io/rb/rx.svg)](https://badge.fury.io/rb/rx)
[![Downloads](http://ruby-gem-downloads-badge.herokuapp.com/rx?type=total)](https://rubygems.org/gems/rx)
[![Coverage](https://codecov.io/gh/bittrance/rxruby/branch/master/graph/badge.svg)](https://codecov.io/gh/bittrance/rxruby)
[![Code Climate](https://codeclimate.com/github/bittrance/rxruby/badges/gpa.svg)](https://codeclimate.com/github/bittrance/rxruby)

# Taking RxRuby across the finishing line

[Original README introducing RxRuby](https://github.com/ReactiveX/RxRuby/tree/master/readme.md)

This fork is an attempt to complete [RxRuby](https://github.com/ReactiveX/RxRuby) which appear to have been abandoned relatively close to completing a first version.

Reactive Extensions is becoming an established style, much thanks to Angular using RxJS, which has heavily inspired RxRuby. RxRuby can help in some simple cases (e.g. operating on infinite streams), but its real value lies in helping make development of multi-threaded stream processing feasible on MRI. First, it takes care of most of the concurrency complexity. It also makes it easy to write code that can be unit tested without having to cope with extensive cross-thread coordination (especially painful on MRI because Ruby is short on concurrency primitives).

Therefore the goal of this push is to achieve feature parity with RxJS 5 and good internal thread safety.

### Milestone 1: Unit test coverage
Get test coverage above 99% and iron out any bugs found; the current codebase appears to have numerous shallow bugs. RxJS 5 is the authoritative source of expected behaviour, so some RxRuby interface changes may be needed to follow. Tag release as 0.1.0 so that it can be securely referenced from Gemfile.

Unit test coverage on development branch:

![RxRuby test coverage](https://codecov.io/gh/bittrance/rxruby/branch/development/graphs/sunburst.svg)

It's gonna be green, yo!

### Milestone 2: Submit changes upstream
The goal of this effort is to improve the existing "rx" gem on RubyGems rather than to release a forked gem. These changes would ideally be merged upstream.

### Milestone 3: API documentation  and introduction
Complete rdoc API documentation and write a proper introduction so that new users understand how to apply RxRuby to their own problems. This also includes making sure that the API is as close to RxJS 5 as is reasonable. Release as 0.2.0.

### Milestone 4: Properly thread-safe
Write a concurrency test suite to straighten out the RxRuby components that need to be properly concurrent in order to provide the one-event-at-a-time guarantee on which users and most operators depend. Release 0.5.0.
