$LOAD_PATH.unshift File.dirname(__FILE__)

require 'ffmpeg/movie'
require 'ffmpeg/transcoder'
require 'ffmpeg/encoding_options'
 
module FFMPEG
  VERSION = '0.4.2'
end