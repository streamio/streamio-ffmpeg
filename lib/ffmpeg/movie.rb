require 'time'

module FFMPEG
  class Movie
    attr_reader :path, :duration, :time, :bitrate, :rotation, :creation_time
    attr_reader :audio_streams, :video_streams, :subtitles
    attr_reader :container


    LANGUAGE_MAP = {
      'deu' => 'ger',
      'und' => nil
    }
   
    def self.language(value)
      LANGUAGE_MAP.include?(value) ? LANGUAGE_MAP[value] : value
    end

    def initialize(path)
      raise Errno::ENOENT, "the file '#{path}' does not exist" unless File.exists?(path)

      @path = path

      # ffmpeg will output to stderr
      output = Open3.popen3(FFMPEG.ffmpeg_binary, '-i', path) { |stdin, stdout, stderr| stderr.read }

      fix_encoding(output)

      output[/Input \#\d+\,\s*(\S+),\s*from/]
      @container = $1

      output[/Duration: (\d{2}):(\d{2}):(\d{2}\.\d{2})/]
      @duration = ($1.to_i*60*60) + ($2.to_i*60) + $3.to_f

      output[/start: (\d*\.\d*)/]
      @time = $1 ? $1.to_f : 0.0

      output[/creation_time {1,}: {1,}(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})/]
      @creation_time = $1 ? Time.parse("#{$1}") : nil

      output[/bitrate: (\d*)/]
      @bitrate = $1 ? $1.to_i : nil

      if output[/rotate\ {1,}:\ {1,}(\d*)/]
        @rotation = $1.to_i
      elsif output[/displaymatrix: rotation of -(\d+)\./]
        @rotation = $1.to_i
      end

      @audio_streams = []
      @video_streams = []
      @subtitles     = []
      
      # parse streams
      output.scan(/(\((\w+)\))?: (Audio|Video|Subtitle): (.+)/).each do |stream|
        language = self.class.language(stream[1])
        raw      = stream[3]
        
        case stream[2]
          when 'Audio'
            @audio_streams << AudioStream.new(language, raw)
          when 'Video'
            @video_streams << VideoStream.new(language, raw)
          when 'Subtitle'
            @subtitles << Subtitle.new(language, raw)
        end
      end

      @invalid = true if @video_streams.empty? && @audio_streams.empty?
      @invalid = true if output.include?("is not supported")
      @invalid = true if output.include?("could not find codec parameters")
    end

    def valid?
      not @invalid
    end

    def uncertain_duration?
      @uncertain_duration
    end
    
    def audio_channels
      audio_streams.map(&:channels).compact
    end
    
    # delegate some methods to the first audio_stream
    %w( codec sample_rate ).each do |method|
      define_method method do
        (stream = audio_streams.first) && stream.send(method)
      end
    end
    
    # delegate some methods to the first video_stream
    %w( resolution width height colorspace sar dar calculated_aspect_ratio calculated_pixel_aspect_ratio frame_rate ).each do |method|
      define_method method do
        (stream = video_streams.first) && stream.send(method)
      end
    end
    
    def video_codec
      video_streams.any? ? video_streams.first.codec : nil
    end

    def size
      File.size(@path)
    end

    def transcode(output_file, options = EncodingOptions.new, transcoder_options = {}, &block)
      Transcoder.new(self, output_file, options, transcoder_options).run &block
    end

    def screenshot(output_file, options = EncodingOptions.new, transcoder_options = {}, &block)
      Transcoder.new(self, output_file, options.merge(screenshot: true), transcoder_options).run &block
    end

    protected

    def fix_encoding(output)
      output[/test/] # Running a regexp on the string throws error if it's not UTF-8
    rescue ArgumentError
      output.force_encoding("ISO-8859-1")
    end
  end
end
