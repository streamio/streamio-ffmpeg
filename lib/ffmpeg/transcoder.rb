require 'open3'
require 'shellwords'

module FFMPEG
  class Transcoder
    @@timeout = 200

    def self.timeout=(time)
      @@timeout = time == false ? false : time.to_i
    end

    def self.timeout
      @@timeout
    end

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
    
    # ffmpeg <  0.8: frame=  413 fps= 48 q=31.0 size=    2139kB time=16.52 bitrate=1060.6kbits/s
    # ffmpeg >= 0.8: frame= 4855 fps= 46 q=31.0 size=   45306kB time=00:02:42.28 bitrate=2287.0kbits/
    def run
      command = "#{FFMPEG.ffmpeg_binary} -y -i #{Shellwords.escape(@movie.path)} #{@raw_options} #{Shellwords.escape(@output_file)}"
      FFMPEG.logger.info("Running transcoding...\n#{command}\n")
      output = ""
      last_output = nil
      Open3.popen3(command) do |stdin, stdout, stderr, wait_thr|
        pid = wait_thr.pid
        begin
          yield(0.0) if block_given?
          next_line = Proc.new do |line|
            fix_encoding(line)
            output << line
            if line.include?("time=")
              if line =~ /time=(\d+):(\d+):(\d+.\d+)/ # ffmpeg 0.8 and above style
                time = ($1.to_i * 3600) + ($2.to_i * 60) + $3.to_f
              elsif line =~ /time=(\d+.\d+)/ # ffmpeg 0.7 and below style
                time = $1.to_f
              else # better make sure it wont blow up in case of unexpected output
                time = 0.0
              end
              progress = time / @movie.duration
              yield(progress) if block_given?
            end
            if line =~ /Unsupported codec/
              FFMPEG.logger.error "Failed encoding...\nCommand\n#{command}\nOutput\n#{output}\n"
              raise "Failed encoding: #{line}"
            end
          end
          
          if @@timeout != false
            stderr.each_with_timeout(@@timeout, "r", &next_line)
          else
            stderr.each("r", &next_line)
          end
            
        rescue Timeout::Error => e
          Process.kill('SIGKILL', pid)
          FFMPEG.logger.error "Process hung...\nCommand\n#{command}\nOutput\n#{output}\n"
          raise "Process hung"
        end
      end

      if encoding_succeeded?
        yield(1.0) if block_given?
        FFMPEG.logger.info "Transcoding of #{@movie.path} to #{@output_file} succeeded\n"
      else
        errors = "Errors: #{@errors.join(", ")}. "
        FFMPEG.logger.error "Failed encoding...\n#{command}\n\n#{output}\n#{errors}\n"
        raise FFMPEG::Error, "Failed encoding.#{errors}Full output: #{output}"
      end
      
      encoded
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
    def apply_transcoder_options
      return if @movie.calculated_aspect_ratio.nil?
      case @transcoder_options[:preserve_aspect_ratio].to_s
      when "width"
        new_height = @raw_options.width / @movie.calculated_aspect_ratio
        new_height = new_height.ceil.even? ? new_height.ceil : new_height.floor
        new_height += 1 if new_height.odd? # needed if new_height ended up with no decimals in the first place
        @raw_options[:resolution] = "#{@raw_options.width}x#{new_height}"
      when "height"
        new_width = @raw_options.height * @movie.calculated_aspect_ratio
        new_width = new_width.ceil.even? ? new_width.ceil : new_width.floor
        new_width += 1 if new_width.odd?
        @raw_options[:resolution] = "#{new_width}x#{@raw_options.height}"
      end
    end
    
    def fix_encoding(output)
      output[/test/]
    rescue ArgumentError
      output.force_encoding("ISO-8859-1")
    end
  end
end
