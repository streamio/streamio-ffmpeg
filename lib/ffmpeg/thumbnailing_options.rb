module FFMPEG
  class ThumnbailingOptions
    attr_reader :preceding, :following
    DEFAULT_POSITION = 4
    ##
    # Position is in seconds
    # output 
    def initialize(options = {})
      position  = options.has_key?(:position) ? options[:position]  : DEFAULT_POSITION
      width     = options.has_key?(:width)    ? options[:width]     : nil
      height    = options.has_key?(:height)   ? options[:height]    : nil
      
      @preceding    = "-itsoffset -#{position}"
      @following    = "-vcodec mjpeg -vframes 1 -an -f rawvideo"
      unless height.nil? and width.nil?
        @following += " -s #{width}x#{height}"
      end
    end
  end
end