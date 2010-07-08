module FFMPEG
  class EncodingOptions < Hash
    def initialize(options = {})
      merge!(options)
    end
    
    def to_s
      params = collect do |key, value|
        send("convert_#{key}", value) if value && supports_option?(key)
      end
      
      # put the preset parameters last
      params = params.reject { |p| p =~ /\-.pre/ } + params.select { |p| p =~ /\-.pre/ }
      
      params_string = params.join(" ")
      params_string << " #{convert_aspect(calculate_aspect)}" if calculate_aspect?
      params_string
    end
    
    def width
      self[:resolution].split("x").first.to_i rescue nil
    end
    
    def height
      self[:resolution].split("x").last.to_i rescue nil
    end
    
    private
    def supports_option?(option)
      option = RUBY_VERSION < "1.9" ? "convert_#{option}" : "convert_#{option}".to_sym
      private_methods.include?(option)
    end
    
    def convert_aspect(value)
      "-aspect #{value}"
    end
    
    def calculate_aspect
      width, height = self[:resolution].split("x")
      width.to_f / height.to_f
    end
    
    def calculate_aspect?
      self[:aspect].nil? && self[:resolution]
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
      "-b #{k_format(value)}"
    end
    
    def convert_audio_codec(value)
      "-acodec #{value}"
    end
    
    def convert_audio_bitrate(value)
      "-ab #{k_format(value)}"
    end
    
    def convert_audio_sample_rate(value)
      "-ar #{value}"
    end
    
    def convert_audio_channels(value)
      "-ac #{value}"
    end
    
    def convert_video_max_bitrate(value)
      "-maxrate #{k_format(value)}"
    end
    
    def convert_video_min_bitrate(value)
      "-minrate #{k_format(value)}"
    end
    
    def convert_buffer_size(value)
      "-bufsize #{k_format(value)}"
    end
    
    def convert_video_bitrate_tolerance(value)
      "-bt #{k_format(value)}"
    end
    
    def convert_threads(value)
      "-threads #{value}"
    end
    
    def convert_video_preset(value)
      "-vpre #{value}"
    end
    
    def convert_audio_preset(value)
      "-apre #{value}"
    end
    
    def convert_file_preset(value)
      "-fpre #{value}"
    end
    
    def convert_custom(value)
      value
    end
    
    def k_format(value)
      value.to_s.include?("k") ? value : "#{value}k"
    end
  end
end
