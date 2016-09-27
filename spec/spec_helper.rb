require 'bundler'
Bundler.require

require 'fileutils'
require 'webmock/rspec'
WebMock.allow_net_connect!

FFMPEG.logger = Logger.new(nil)

RSpec.configure do |config|
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true

  config.before(:each) do
    stub_request(:head, /redirect-example.com/).
        with(:headers => {'Accept'=>'*/*', 'User-Agent' => 'Ruby'}).
        to_return(status: 302, headers: {
            location: 'http://127.0.0.1:8000/awesome%20movie.mov'
        })
    stub_request(:head, 'http://127.0.0.1:8000/deep_path/awesome%20movie.mov').
        with(:headers => {'Accept'=>'*/*', 'User-Agent' => 'Ruby'}).
        to_return(status: 302, headers: {
            location: '/awesome%20movie.mov'
        })
    stub_request(:head, 'http://127.0.0.1:8000/awesome%20movie.mov?fail=1').
        with(:headers => {'Accept'=>'*/*', 'User-Agent' => 'Ruby'}).
        to_return(status: 404, headers: { })
    stub_request(:head, /toomany-redirects-example/).
        with(:headers => {'Accept'=>'*/*', 'User-Agent' => 'Ruby'}).
        to_return(status: 302, headers: {
            location: '/awesome%20movie.mov'
        })

  end
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

FileUtils.rm_rf(tmp_path)
FileUtils.mkdir_p tmp_path
