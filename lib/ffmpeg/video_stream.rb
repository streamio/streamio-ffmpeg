module FFMPEG
  class VideoStream
    attr_reader :language, :codec, :colorspace, :bitrate, :resolution, :width, :height, :sar, :dar, :frame_rate
    
    def initialize(language, raw)
      @raw = raw
      @codec, @colorspace, resolution, bitrate = FFMPEG.parse_options(raw)
      @bitrate = $1.to_i if bitrate =~ %r(\A(\d+) kb/s\Z)
      @resolution = resolution.split(" ").first rescue nil # get rid of [PAR 1:1 DAR 16:9]
      @sar = $1 if raw[/[SP]AR (\d+:\d+)/]
      @dar = $1 if raw[/DAR (\d+:\d+)/]
      @frame_rate = raw[/(\d*\.?\d*)\s?fps/] ? $1.to_f : nil
      
      if @resolution
        w, h = @resolution.split("x")
        @width  = w.to_i
        @height = h.to_i
      end
    end
    
    def to_s
      @raw
    end

    def calculated_aspect_ratio
      aspect_from_dar || aspect_from_dimensions
    end

    def calculated_pixel_aspect_ratio
      aspect_from_sar || 1
    end

    protected

    def aspect_from_dar
      return nil unless dar
      w, h = dar.split(":")
      aspect = w.to_f / h.to_f
      aspect.zero? ? nil : aspect
    end

    def aspect_from_sar
      return nil unless sar
      w, h = sar.split(":")
      aspect = w.to_f / h.to_f
      aspect.zero? ? nil : aspect
    end

    def aspect_from_dimensions
      aspect = width.to_f / height.to_f
      aspect.nan? ? nil : aspect
    end
    
  end
end
