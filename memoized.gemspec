$:.push File.expand_path("../lib", __FILE__)
require "memoized/version"

Gem::Specification.new do |s|
  s.name        = "memoized"
  s.version     = Memoized::VERSION
  s.authors     = ["Barun Singh", "Henning Koch"]
  s.homepage    = "https://github.com/makandra/memoized"
  s.summary     = "Memoized caches the results of your method calls"
  s.description = s.summary
  s.license = 'MIT'
  s.metadata    = {
    'source_code_uri' => s.homepage,
    'bug_tracker_uri' => 'https://github.com/makandra/memoized/issues',
    'changelog_uri' => 'https://github.com/makandra/memoized/blob/master/CHANGELOG.md',
    'rubygems_mfa_required' => 'true',
  }

  s.files         = `git ls-files`.split("\n").select { |f| !File.symlink?(f) && !f.match(%r{^(spec|dev|media|.github)/}) }
  s.require_paths = ["lib"]

  s.bindir = 'exe'
  s.executables = []

  s.required_ruby_version = '>= 3.0.0'
end
