# Knockoff (WIP)

[![Build Status](https://travis-ci.org/sgringwe/knockoff.svg?branch=master)](https://travis-ci.org/sgringwe/knockoff)
[![Gem Version](https://badge.fury.io/rb/knockoff.svg)](https://badge.fury.io/rb/knockoff)

A gem for easily using read replicas. Heavily based off of https://github.com/kenn/slavery and https://github.com/kickstarter/replica_pools gem.

## Library Goals

* Minimal ActiveRecord monkey-patching
* Easy run-time configuration using ENV variables
* Opt-in usage of replicas
* No need to change code when adding/removing replicas
* Be thread safe

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'knockoff'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install knockoff

## Usage

TODO

### Usage Notes

* Do not use prepared statements with this gem

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/knockoff.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

