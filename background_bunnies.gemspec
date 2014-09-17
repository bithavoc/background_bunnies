# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'background_bunnies/version'

Gem::Specification.new do |gem|
  gem.name          = "background_bunnies"
  gem.version       = BackgroundBunnies::VERSION
  gem.authors       = ["bithavoc"]
  gem.email         = ["im@bithavoc.io"]
  gem.description   = 'AMQP based workers'
  gem.summary       = 'Background workers based on AMQP and the bunny gem'
  gem.homepage      = "https://github.com/bithavoc/background_bunnies"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  gem.add_dependency "bunny", ">= 0.9.0.pre7"
  gem.add_dependency "amqp"
  gem.add_development_dependency "rake"
  gem.add_development_dependency "minitest"
end
