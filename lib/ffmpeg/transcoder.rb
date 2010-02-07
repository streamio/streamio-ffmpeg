require 'open3'

module FFMPEG
  class Transcoder
    def initialize(movie, options)
      raise ArgumentError, "you need to specify options[:output_file]" unless options[:output_file]
            
      @movie = movie
      @options = options
    end
    
    def run
      command = "ffmpeg -y -i '#{@movie.path}' #{@options[:raw_options]} '#{@options[:output_file]}'"
      last_output = nil
      Open3.popen3(command) do |stdin, stdout, stderr|
        stderr.each("r") do |line|
          if line =~ /time=(\d+.\d+)/
            time = $1.to_f
            progress = time / @movie.duration
            yield(progress) if block_given?
          end
          if line =~ /Unsupported codec/
            raise "Failed encoding: #{line}"
          end
          last_output = line
        end
      end  

      if encoding_succeeded?
        yield(1.0) if block_given?
      else
        raise "Failed encoding. Last output: #{last_output}. Original duration: #{@movie.duration}. Encoded duration: #{encoded.duration}."
      end
      
      encoded
    end
    
    def encoding_succeeded?
      precision = 1.1
      encoded.valid? && !(encoded.duration >= (@movie.duration * precision) or encoded.duration <= (@movie.duration / precision))
    end
    
    def encoded
      @encoded ||= Movie.new(@options[:output_file])
    end
  end
end
