module FFMPEG
  module Transcoders
    module Scaler
      private

        def preserve_aspect_ratio?
          @movie.calculated_aspect_ratio && 
          [:width, :height].include?(@transcoder_options[:preserve_aspect_ratio])
        end
        
        # Scaling with autorotation 
        #
        # If scaled in conjuction with autorotation 
        # and the rotation results in an orientation change
        # we must "invert" the side that is preserved
        # as scaling takes place prior to rotation
        #
        # Example: 
        #
        # Original: resolution => 640x480, rotation => 90 
        # Requested: resolution => 660x2, preserved_aspect_ration => :width, autorotate => true
        #
        # => the orientation will change from landscape to portrait
        # => we have to invert the preserved_aspect_ration => :height
        #
        # Expected Output: resolution => 660x880
        #
        # Required Encoding (ffmpeg version < 1.0, scales before rotating, not implemented): resolution => 880x660
        # Required Encoding (ffmpeg version == 1.0, rotates before scaling, this implementation): resolution => 660x880
        #
        def apply_preserve_aspect_ratio(change_orientation=false)
          return unless preserve_aspect_ratio?

          side = @transcoder_options[:preserve_aspect_ratio]
          size = @raw_options.send(side)
          side = invert_side(side) if change_orientation            

          if @transcoder_options[:enlarge] == false
            original_size = @movie.send(side)
            size = original_size if original_size < size
          end

          case side
          when :width
            new_height = size / @movie.calculated_aspect_ratio
            new_height = evenize(new_height)
            @raw_options[:resolution] = "#{size}x#{new_height}"
          when :height
            new_width = size * @movie.calculated_aspect_ratio
            new_width = evenize(new_width)
            @raw_options[:resolution] = "#{new_width}x#{size}"
          end

          invert_resolution if change_orientation 
        end

        def invert_side(side)
          side == :height ? :width : :height
        end

        def invert_resolution
          @raw_options[:resolution] = @raw_options[:resolution].split("x").reverse.join("x")
        end
        
        # ffmpeg requires full, even numbers for its resolution string -- this method ensures that
        def evenize(number)
          number = number.ceil.even? ? number.ceil : number.floor
          number.odd? ? number += 1 : number # needed if new_height ended up with no decimals in the first place
        end

    end
  end
end

