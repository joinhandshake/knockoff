## Unreleased

## 1.5.0

Update to be Rails 7.0 compatible. Drops support for ruby 2.6 and Rails 6.0-

## 1.4.0

Update to be Rails 6.1 compatible

## 1.1.1

- Drop Ruby 2.3 support
- Add Ruby 2.6 and 2.7 support
- Fix a deprecation warning in Rails 6

## 1.1.0

- Allow for not checking `inside_transaction?` on primary database (https://github.com/joinhandshake/knockoff/pull/13)
- Allow setting `Knockoff.default_target` to set the default target other than `:primary` (https://github.com/joinhandshake/knockoff/pull/11)
- Drop Ruby 2.2 support
- Add Ruby 2.5 support
