# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'weskit/version'

Gem::Specification.new do |s|
  s.name        = 'weskit'
  s.version     = Weskit::VERSION
  s.authors     = ['f6p']
  s.email       = ['filip.pyda@gmail.com']
  s.homepage    = 'https://github.com/f6p/weskit'
  s.summary     = 'Ruby utilies for BfW'
  s.description = 'Tools for interacting with Wesnoth Markup Language, MP Server and such.'

  # s.rubyforge_project = 'weskit'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename f }
  s.require_paths = ['lib']

  s.add_development_dependency 'kpeg', '~>1.0.0'
  s.add_development_dependency 'rake', '>=0.9.2.2'
  s.add_development_dependency 'rspec', '~>2.14.0'
  s.add_runtime_dependency 'term-ansicolor', '>=1.3.0'
end
