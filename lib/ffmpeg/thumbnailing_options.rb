module FFMPEG
  class ThumnbailingOptions < Hash
    attr_reader :preceding, :following
    ##
    # Position is in seconds
    # output 
    def initialize(position=4,height=nil,width=nil)
      @preceding    = "-itsoffset -#{position}"
      @following    = "-vcodec mjpeg -vframes 1 -an -f rawvideo"
      unless height.nil? and width.nil?
        @following += "-s #{width}x#{height}"
      end
    end
  end
end