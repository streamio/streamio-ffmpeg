$LOAD_PATH.unshift File.dirname(__FILE__)

require 'logger'
require 'stringio'

require 'ffmpeg/version'
require 'ffmpeg/errors'
require 'ffmpeg/movie'
require 'ffmpeg/io_monkey'
require 'ffmpeg/transcoder'
require 'ffmpeg/encoding_options'

module FFMPEG
  # FFMPEG logs information about its progress when it's transcoding.
  # Jack in your own logger through this method if you wish to.
  #
  # @param [Logger] log your own logger
  # @return [Logger] the logger you set
  def self.logger=(log)
    @logger = log
  end

  # Get FFMPEG logger.
  #
  # @return [Logger]
  def self.logger
    return @logger if @logger
    logger = Logger.new(STDOUT)
    logger.level = Logger::INFO
    @logger = logger
  end

  # Set the path of the ffmpeg binary.
  # Can be useful if you need to specify a path such as /usr/local/bin/ffmpeg
  #
  # @param [String] path to the ffmpeg binary
  # @return [String] the path you set
  def self.ffmpeg_binary=(bin)
    @ffmpeg_binary = bin
  end

  # Get the path to the ffmpeg binary
  #
  # @return [String] the path to the ffmpeg binary
  def self.ffmpeg_binary
    @ffmpeg_binary ||= find_ffmpeg_binary
  end

  # Tries find the ffmpeg binary
  #
  # @return [String] the path to the ffmpeg binary
  def self.find_ffmpeg_binary
    %w(
      /usr/bin/avconv
      /usr/bin/ffmpeg
      /usr/local/bin/avconv
      /usr/local/bin/ffmpeg
    ).each do |path|
      return path if File.exists?(path)
    end

    raise "unable to find ffmpeg binary"
  end

end
