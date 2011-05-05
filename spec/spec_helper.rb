require 'bundler'
Bundler.require

require 'fileutils'

FFMPEG.logger = Logger.new(nil)

RSpec.configure do |config|
end

def fixture_path
  @fixture_path ||= File.join(File.dirname(__FILE__), 'fixtures')
end

def tmp_path  
  @tmp_path ||= File.join(File.dirname(__FILE__), "..", "tmp")
end

FileUtils.mkdir_p tmp_path
