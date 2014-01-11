# -*- encoding: utf-8 -*-
require File.expand_path('../lib/drsi/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name          = "drsi"
  gem.version       = Drsi::VERSION
  gem.authors       = ["Lorenzo Tello"]
  gem.email         = ["ltello8a@gmail.com"]
  gem.homepage      = "http://github.com/ltello/drsi"
  gem.description   = "Make DCI paradigm available to Ruby applications"
  gem.summary       = "Make DCI paradigm available to Ruby applications by enabling developers defining contexts subclassing the class DCI::Context. You define roles inside the definition. Match roles and player objects in context instantiation. Single Identity approach."
  gem.licenses      = ["MIT"]

  gem.rubyforge_project = "drsi"

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.require_paths = ["lib"]

  # specify any dependencies here; for example:
  gem.add_development_dependency "rspec", "~> 2.0"
  # s.add_runtime_dependency "rest-client"

end
