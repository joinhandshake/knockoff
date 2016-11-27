# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'knockoff/version'

Gem::Specification.new do |spec|
  spec.name          = "knockoff"
  spec.version       = Knockoff::VERSION
  spec.authors       = ["Scott Ringwelski"]
  spec.email         = ["scott@joinhandshake.com"]

  spec.summary       = %q{A gem for using your replica databases}
  spec.homepage      = "https://github.com/sgringwe/knockoff"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'activerecord', '>= 4.0.0'
  spec.add_runtime_dependency 'request_store_rails', '>= 1.0.0'

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency 'sqlite3'
end
