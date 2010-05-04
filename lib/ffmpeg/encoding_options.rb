# Include support for -bt -maxrate -minrate -bufsize?

module FFMPEG
  class EncodingOptions < Hash
    def initialize(options = {})
      merge!(options)
    end
    
    def to_s
      collect do |key, value|
        send("convert_#{key}", value) if supports_option?(key)
      end.join(" ")
    end
    
    private
    def supports_option?(option)
      private_methods.include?("convert_#{option}")
    end
    
    def convert_croptop(value)
      "-croptop #{value}"
    end
    
    def convert_cropbottom(value)
      "-cropbottom #{value}"
    end
    
    def convert_cropleft(value)
      "-cropleft #{value}"
    end
    
    def convert_cropright(value)
      "-cropright #{value}"
    end
    
    def convert_video_codec(value)
      "-vcodec #{value}"
    end
    
    def convert_frame_rate(value)
      "-r #{value}"
    end
    
    def convert_resolution(value)
      "-s #{value}"
    end
    
    def convert_video_bitrate(value)
      "-b #{value}#{k_format(value)}"
    end
    
    def convert_audio_codec(value)
      "-acodec #{value}"
    end
    
    def convert_audio_bitrate(value)
      "-ab #{value}#{k_format(value)}"
    end
    
    def convert_audio_sample_rate(value)
      "-ar #{value}"
    end
    
    def convert_audio_channels(value)
      "-ac #{value}"
    end
    
    def convert_custom(value)
      value
    end
    
    def k_format(value)
      "k" unless value.to_s.include?("k")
    end
  end
end
