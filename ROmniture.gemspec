$:.push File.expand_path("../lib", __FILE__)
require "romniture/version"

Gem::Specification.new do |s|
  s.name              = "romniture"
  s.version           = ROmniture::VERSION
  s.authors           = ["Mike Sukmanowsky"]
  s.email             = ["mike.sukmanowsky@gmail.com"]
  s.homepage          = "http://github.com/msukmanowsky/ROmniture"
  s.summary           = "Use Omniture's REST API with ease."
  s.description       = "A library that allows access to Omniture's REST API libraries (developer.omniture.com)"

  s.rubyforge_project = s.name

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  
  s.add_runtime_dependency("httpi")
  s.add_runtime_dependency("json")  
 
end