module FFMPEG
  class AudioStream
    attr_reader :language, :codec, :bitrate, :sample_rate, :channels
    
    def initialize(language, raw)
      @language = language
      @raw      = raw

      if raw.include?(",") # parsable ?
        @codec, sample_rate, @channels, unused, bitrate = FFMPEG.parse_options raw
        @bitrate = bitrate =~ %r(\A(\d+) kb/s) ? $1.to_i : nil
        @sample_rate = sample_rate[/\d*/].to_i
      end
    end
    
    def to_s
      @raw
    end
    
    def channels
      return nil unless @channels
      return @channels[/\d*/].to_i if @channels["channels"]
      return 1 if @channels["mono"]
      return 2 if @channels["stereo"]
      return 6 if @channels["5.1"]
    end
  end
end
