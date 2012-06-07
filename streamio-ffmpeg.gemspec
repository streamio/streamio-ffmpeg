# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require "ffmpeg/version"

Gem::Specification.new do |s|
  s.name        = "streamio-ffmpeg"
  s.version     = FFMPEG::VERSION
  s.authors     = ["David Backeus"]
  s.email       = ["david@streamio.se"]
  s.homepage    = "http://github.com/streamio/streamio-ffmpeg"
  s.summary     = "Reads metadata and transcodes movies."
  s.description = "Simple yet powerful wrapper around ffmpeg to get metadata from movies and do transcoding."
  
  s.add_development_dependency("rspec", ">= 2.7")
  s.add_development_dependency("rake", ">= 0.9.2")

  s.files        = Dir.glob("lib/**/*") + %w(README.md LICENSE CHANGELOG)
end
