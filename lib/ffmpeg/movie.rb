require 'open3'

module FFMPEG
  class Movie
    attr_reader :duration, :video_stream, :audio_stream, :video_codec, :colorspace, :resolution
    
    def initialize(path)
      raise Errno::ENOENT, "the file '#{path}' does not exist" unless File.exists?(path)
      
      stdin, stdout, stderr = Open3.popen3("ffmpeg -i #{path}") # Output will land in stderr
      output = stderr.read
      
      @valid = output[/Unknown format/].nil?
      
      output[/Duration: (\d{2}):(\d{2}):(\d{2}\.\d{1})/]
      @duration = ($1.to_i*60*60) + ($2.to_i*60) + $3.to_f
      
      output[/Video: (.*)/]
      @video_stream = $1
      
      output[/Audio: (.*)/]
      @audio_stream = $1
      
      if video_stream
        @video_codec, @colorspace, resolution = video_stream.split(/\s?,\s?/)
        @resolution = resolution.split(" ").first # get rid of [PAR 1:1 DAR 16:9]
      end
    end
    
    def valid?
      @valid
    end
    
    def width
      resolution.split("x")[0].to_i rescue nil
    end
    
    def height
      resolution.split("x")[1].to_i rescue nil
    end
  end
end