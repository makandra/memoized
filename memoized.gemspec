$:.push File.expand_path("../lib", __FILE__)
require "memoized/version"

Gem::Specification.new do |s|
  s.name        = "memoized"
  s.version     = Memoized::VERSION
  s.authors     = ["Barun Singh", "Henning Koch"]
  s.homepage    = "https://github.com/makandra/memoized"
  s.summary     = "Memoized caches the results of your method calls"
  s.description = s.summary

  s.files         = `git ls-files`.split("\n").reject { |path| File.lstat(path).symlink? }
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n").reject { |path| File.lstat(path).symlink? }
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.license = 'MIT'

  s.add_development_dependency('rake', '~> 10.4.2')
  s.add_development_dependency('rspec', '~> 3.5.0')
  s.add_development_dependency('timecop', '~> 0.8.0')
end
