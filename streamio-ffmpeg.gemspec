# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require "ffmpeg/version"

Gem::Specification.new do |s|
  s.name        = "streamio-ffmpeg"
  s.version     = FFMPEG::VERSION
  s.authors     = ["Rackfish AB"]
  s.email       = ["support@rackfish.com", "bikeath1337.com"]
  s.homepage    = "http://github.com/streamio/streamio-ffmpeg"
  s.summary     = "Wraps ffmpeg to read metadata and transcodes videos."

  s.add_dependency('multi_json', '~> 1.8')

  s.add_development_dependency("rspec", "~> 2.14")
  s.add_development_dependency("rake", "~> 10.1")

  s.files        = Dir.glob("lib/**/*") + %w(README.md LICENSE CHANGELOG)
end
