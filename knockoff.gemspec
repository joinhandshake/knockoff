# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'knockoff/version'

Gem::Specification.new do |spec|
  spec.name          = "knockoff"
  spec.version       = Knockoff::VERSION
  spec.authors       = ["Scott Ringwelski"]
  spec.email         = ["me@sgringwe.com"]

  spec.summary       = %q{A gem for easily using read replicas}
  spec.homepage      = "https://github.com/sgringwe/knockoff"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'activerecord', '>= 4.0.0'
  spec.add_runtime_dependency 'activesupport', '>= 4.0.0'

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency 'sqlite3'
end
