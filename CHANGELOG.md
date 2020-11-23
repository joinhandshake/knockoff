## Unreleased

## 1.1.1

- Drop Ruby 2.3 support
- Add Ruby 2.6 and 2.7 support
- Fix a deprecation warning in Rails 6

## 1.1.0

- Allow for not checking `inside_transaction?` on primary database (https://github.com/joinhandshake/knockoff/pull/13)
- Allow setting `Knockoff.default_target` to set the default target other than `:primary` (https://github.com/joinhandshake/knockoff/pull/11)
- Drop Ruby 2.2 support
- Add Ruby 2.5 support