require 'bundler'
Bundler.require

require 'fileutils'

FFMPEG.logger = Logger.new(nil)

RSpec.configure do |config|
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
end

def fixture_path
  @fixture_path ||= File.join(File.dirname(__FILE__), 'fixtures')
end

def tmp_path
  @tmp_path ||= File.join(File.dirname(__FILE__), "..", "tmp")
end

def start_web_server
  @server = WEBrick::HTTPServer.new(
      Port: 8000,
      DocumentRoot: "#{fixture_path}/movies",
      Logger: WEBrick::Log.new(File.open(File::NULL, 'w')),
      AccessLog: []
  )
  Thread.new { @server.start }
end

def stop_web_server
  @server.shutdown
end


FileUtils.mkdir_p tmp_path
