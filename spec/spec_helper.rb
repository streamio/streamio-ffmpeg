$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'streamio-ffmpeg'
require 'spec'
require 'spec/autorun'
require 'fileutils'

FFMPEG.logger = Logger.new(nil)

Spec::Runner.configure do |config|
end

def fixture_path
  @fixture_path ||= File.join(File.dirname(__FILE__), 'fixtures')
end

def tmp_path  
  @tmp_path ||= File.join(File.dirname(__FILE__), "..", "tmp")
end

FileUtils.mkdir_p tmp_path
