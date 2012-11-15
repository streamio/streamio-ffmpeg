module FFMPEG
  module Transcoders
    module Scaler
      private

        def preserve_aspect_ratio?
          @movie.calculated_aspect_ratio && 
          %w(width height).include?(@transcoder_options[:preserve_aspect_ratio].to_s)
        end
        
        def apply_preserve_aspect_ratio(change_orientation=false)
          return unless preserve_aspect_ratio?
          side = @transcoder_options[:preserve_aspect_ratio].to_s
          size = @raw_options.send(side)
          side = invert_side(side) if change_orientation            
          set_new_resolution(side, size)
        end

        def set_new_resolution(side, size)
          case side
          when "width"
            new_height = size / @movie.calculated_aspect_ratio
            new_height = evenize(new_height)
            @raw_options[:resolution] = "#{size}x#{new_height}"
          when "height"
            new_width = size * @movie.calculated_aspect_ratio
            new_width = evenize(new_width)
            @raw_options[:resolution] = "#{new_width}x#{size}"
          end
        end

        def invert_side(side)
          side == 'height' ? 'width' : 'height'
        end
        
        # ffmpeg requires full, even numbers for its resolution string -- this method ensures that
        def evenize(number)
          number = number.ceil.even? ? number.ceil : number.floor
          number.odd? ? number += 1 : number # needed if new_height ended up with no decimals in the first place
        end

    end
  end
end

