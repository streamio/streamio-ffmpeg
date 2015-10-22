require 'open3'
require 'shellwords'

module FFMPEG
  class Transcoder
    @@timeout = 30

    def self.timeout=(time)
      @@timeout = time
    end

    def self.timeout
      @@timeout
    end

    def initialize(movie, output_file, options = EncodingOptions.new, transcoder_options = {})
      @movie = movie
      @output_file = output_file

      if options.is_a?(String)
        @raw_options = "-i #{Shellwords.escape(@movie.path)} " + options
      elsif options.is_a?(EncodingOptions)
        @raw_options = options.merge(:input => @movie.path) unless options.include? :input
      elsif options.is_a?(Hash)
        @raw_options = EncodingOptions.new(options.merge(:input => @movie.path))
      else
        raise ArgumentError, "Unknown options format '#{options.class}', should be either EncodingOptions, Hash or String."
      end

      @transcoder_options = transcoder_options
      @errors = []

      apply_transcoder_options
    end

    def run(&block)
      transcode_movie(&block)
      if @transcoder_options[:validate]
        validate_output_file(&block)
        return encoded
      else
        return nil
      end
    end

    def encoding_succeeded?
      @errors << "no output file created" and return false unless File.exists?(@output_file)
      @errors << "encoded file is invalid" and return false unless encoded.valid?
      true
    end

    def encoded
      @encoded ||= Movie.new(@output_file)
    end

    private
    # frame= 4855 fps= 46 q=31.0 size=   45306kB time=00:02:42.28 bitrate=2287.0kbits/
    def transcode_movie
      @command = "#{FFMPEG.ffmpeg_binary} -y #{@raw_options} #{Shellwords.escape(@output_file)}"
      FFMPEG.logger.info("Running transcoding...\n#{@command}\n")
      @output = ""

      Open3.popen3(@command) do |stdin, stdout, stderr, wait_thr|
        begin
          yield(0.0) if block_given?
          next_line = Proc.new do |line|
            fix_encoding(line)
            @output << line
            if line.include?("time=")
              if line =~ /time=(\d+):(\d+):(\d+.\d+)/ # ffmpeg 0.8 and above style
                time = ($1.to_i * 3600) + ($2.to_i * 60) + $3.to_f
              else # better make sure it wont blow up in case of unexpected output
                time = 0.0
              end
              progress = time / @movie.duration
              yield(progress) if block_given?
            end
          end

          if @@timeout
            stderr.each_with_timeout(wait_thr.pid, @@timeout, 'size=', &next_line)
          else
            stderr.each('size=', &next_line)
          end

        rescue Timeout::Error => e
          FFMPEG.logger.error "Process hung...\n@command\n#{@command}\nOutput\n#{@output}\n"
          raise Error, "Process hung. Full output: #{@output}"
        end
      end
    end

    def validate_output_file(&block)
      if encoding_succeeded?
        yield(1.0) if block_given?
        FFMPEG.logger.info "Transcoding of #{@movie.path} to #{@output_file} succeeded\n"
      else
        errors = "Errors: #{@errors.join(", ")}. "
        FFMPEG.logger.error "Failed encoding...\n#{@command}\n\n#{@output}\n#{errors}\n"
        raise Error, "Failed encoding.#{errors}Full output: #{@output}"
      end
    end

    def apply_transcoder_options
       # if true runs #validate_output_file
      @transcoder_options[:validate] = @transcoder_options.fetch(:validate) { true }

      return if @movie.calculated_aspect_ratio.nil?
      case @transcoder_options[:preserve_aspect_ratio].to_s
      when "width"
        preserve_width(@movie.calculated_aspect_ratio)
      when "height"
        preserve_height(@movie.calculated_aspect_ratio)
      when "fit"
        # need to take rotation into account to compare aspect ratios correctly
        input_aspect_ratio = if @movie.rotation && (@movie.rotation / 90).odd?
                               @movie.height.to_f / @movie.width.to_f
                             else
                               @movie.width.to_f / @movie.height.to_f
                             end
        options_aspect_ratio = @raw_options.width.to_f / @raw_options.height.to_f

        if options_aspect_ratio > input_aspect_ratio
          preserve_height(input_aspect_ratio)
        else
          preserve_width(input_aspect_ratio)
        end
      end
    end

    def preserve_height(input_aspect_ratio)
      new_width = fix_dimension(@raw_options.height * input_aspect_ratio)
      @raw_options[:resolution] = "#{new_width}x#{@raw_options.height}"
    end

    def preserve_width(input_aspect_ratio)
      new_height = fix_dimension(@raw_options.width / input_aspect_ratio)
      @raw_options[:resolution] = "#{@raw_options.width}x#{new_height}"
    end

    def fix_dimension(n)
      n = n.ceil.even? ? n.ceil : n.floor
      n += 1 if n.odd? # needed if n ended up with no decimals in the first place
      return n
    end

    def fix_encoding(output)
      output[/test/]
    rescue ArgumentError
      output.force_encoding("ISO-8859-1")
    end
  end
end
