module FFMPEG
  module Transcoders
    module Autorotator
      def apply_autorotate
        return unless autorotate?
        # remove the rotation information on the video stream so rotation-aware players don't rotate twice
        @raw_options[:metadata] = 's:v:0 rotate=0'
        filters = {
          90  => 'transpose=1',
          180 => 'hflip,vflip',
          270 => 'transpose=2'
        }
        @raw_options[:video_filter] = filters[@movie.rotation]
      end

      # we need to know if orientation changes when we scale
      def changes_orientation?
        autorotate? && [90, 270].include?(@movie.rotation)
      end

      def autorotate?
        @transcoder_options[:autorotate] && @movie.rotation && @movie.rotation != 0
      end

    end
  end
end
