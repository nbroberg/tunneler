# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'tunneler/version'

Gem::Specification.new do |spec|
  spec.name          = "tunneler"
  spec.version       = Tunneler::VERSION
  spec.authors       = ["Nels Broberg"]
  spec.email         = ["zifridorio@hotmail.com"]
  spec.description   = %q{Command line tool and ruby gem for SSH tunneling}
  spec.summary       = %q{SSH to server via tunneler host}
  spec.homepage      = "https://github.com/nbroberg/tunneler"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "net-scp"
  spec.add_dependency "net-ssh-gateway"
  spec.add_dependency "trollop"
  
  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "debugger"
end
