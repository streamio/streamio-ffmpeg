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

  # Set the path of the mediainfo binary.
  # Can be useful if you need to specify a path such as /usr/local/bin/mediainfo
  #
  # @param [String] path to the ffmpeg binary
  # @return [String] the path you set
  def self.mediainfo_binary=(bin)
    @mediainfo_binary = bin
  end

  # Set the path of the qtfaststart binary.
  # Can be useful if you need to specify a path such as /usr/local/bin/qtfaststart
  #
  # @param [String] path to the ffmpeg binary
  # @return [String] the path you set
  def self.qtfaststart_binary=(bin)
    @qtfaststart_binary = bin
  end

  def self.cp_mode=(is_enable)
    @cp_mode = is_enable
  end

  # Get the path to the ffmpeg binary, defaulting to 'ffmpeg'
  #
  # @return [String] the path to the ffmpeg binary
  def self.ffmpeg_binary
    @ffmpeg_binary || 'ffmpeg'
  end

  # Get the path to the ffmpeg binary, defaulting to 'mediainfo'
  #
  # @return [String] the path to the ffmpeg binary
  def self.mediainfo_binary
    @mediainfo_binary || 'mediainfo'
  end

  # Get the path to the ffmpeg binary, defaulting to 'qtfaststart'
  #
  # @return [String] the path to the ffmpeg binary
  def self.qtfaststart_binary
    @qtfaststart_binary || 'qtfaststart'
  end

  def self.cp_mode
    @cp_mode == 'true' || @cp_mode == true
  end

end
