require 'open3'

module FFMPEG
  class Transcoder
    def initialize(movie, output_file, options = EncodingOptions.new, transcoder_options = {})
      @movie = movie
      @output_file = output_file
      
      if options.is_a?(String) || options.is_a?(EncodingOptions)
        @raw_options = options
      elsif options.is_a?(Hash)
        @raw_options = EncodingOptions.new(options)
      else
        raise ArgumentError, "Unknown options format '#{options.class}', should be either EncodingOptions, Hash or String."
      end
      
      @transcoder_options = transcoder_options
      @errors = []
      
      apply_transcoder_options
    end
    
    def run
      command = "ffmpeg -y -i '#{@movie.path}' #{@raw_options} '#{@output_file}'"
      FFMPEG.logger.info("Running transcoding...\n#{command}")
      output = ""
      last_output = nil
      Open3.popen3(command) do |stdin, stdout, stderr|
        stderr.each("r") do |line|
          output << line
          if line =~ /time=(\d+.\d+)/
            time = $1.to_f
            progress = time / @movie.duration
            yield(progress) if block_given?
          end
          if line =~ /Unsupported codec/
            FFMPEG.logger.error "Failed encoding...\nCommand\n#{command}\nOutput\n#{output}"
            raise "Failed encoding: #{line}"
          end
          last_output = line
        end
      end

      if encoding_succeeded?
        FFMPEG.logger.info "Transcoding of #{@movie.path} to #{@output_file} succeeded"
        yield(1.0) if block_given?
      else
        errors = @errors.empty? ? "" : "Errors: #{@errors.join(", ")}"
        FFMPEG.logger.error "Failed encoding...\n#{command}\n\n#{output}\n#{errors}"
        raise "Failed encoding. Last output: #{last_output}. #{errors}"
      end
      
      encoded
    end
    
    def encoding_succeeded?
      unless File.exists?(@output_file)
        @errors << "no output file created"
        return false
      end
      
      unless encoded.valid?
        @errors << "encoded file is invalid"
        return false
      end
      
      precision = 1.1
      unless !(encoded.duration >= (@movie.duration * precision) or encoded.duration <= (@movie.duration / precision))
        @errors << "encoded file duration differed from original (original: #{@movie.duration}sec, encoded: #{encoded.duration}sec)"
        return false
      end
      
      true
    end
    
    def encoded
      @encoded ||= Movie.new(@output_file)
    end
    
    private
    def apply_transcoder_options
      return if @movie.calculated_aspect_ratio.nil?
      case @transcoder_options[:preserve_aspect_ratio].to_s
      when "width"
        new_height = @raw_options.width / @movie.calculated_aspect_ratio
        new_height = new_height.ceil.even? ? new_height.ceil : new_height.floor
        @raw_options[:resolution] = "#{@raw_options.width}x#{new_height}"
      when "height"
        new_width = @raw_options.height * @movie.calculated_aspect_ratio
        new_width = new_width.ceil.even? ? new_width.ceil : new_width.floor
        @raw_options[:resolution] = "#{new_width}x#{@raw_options.height}"
      end
    end
  end
end
