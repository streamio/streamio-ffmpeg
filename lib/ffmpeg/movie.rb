require 'time'

module FFMPEG
  class Movie
    attr_reader :path, :duration, :time, :bitrate, :rotation, :creation_time
    attr_reader :video_stream, :video_codec, :video_bitrate, :colorspace, :resolution, :dar
    attr_reader :audio_stream, :audio_codec, :audio_bitrate, :audio_sample_rate
    attr_reader :container

    def initialize(path)
      raise Errno::ENOENT, "the file '#{path}' does not exist" unless File.exists?(path)

      @path = path

      # ffmpeg will output to stderr
      command = "#{FFMPEG.ffmpeg_binary} -i #{Shellwords.escape(path)}"
      output = Open3.popen3(command) { |stdin, stdout, stderr| stderr.read }

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

      output[/rotate\ {1,}:\ {1,}(\d*)/]
      @rotation = $1 ? $1.to_i : nil

      output[/Video:\ (.*)/]
      @video_stream = $1

      output[/Audio:\ (.*)/]
      @audio_stream = $1

      if video_stream
        @video_codec, @colorspace, resolution, video_bitrate = video_stream.split(/\s?,\s?/)
        @video_bitrate = video_bitrate =~ %r(\A(\d+) kb/s\Z) ? $1.to_i : nil
        @resolution = resolution.split(" ").first rescue nil # get rid of [PAR 1:1 DAR 16:9]
        @dar = $1 if video_stream[/DAR (\d+:\d+)/]
      end

      if audio_stream
        @audio_codec, audio_sample_rate, @audio_channels, unused, audio_bitrate = audio_stream.split(/\s?,\s?/)
        @audio_bitrate = audio_bitrate =~ %r(\A(\d+) kb/s\Z) ? $1.to_i : nil
        @audio_sample_rate = audio_sample_rate[/\d*/].to_i
      end

      @invalid = true if @video_stream.to_s.empty? && @audio_stream.to_s.empty?
      @invalid = true if output.include?("is not supported")
      @invalid = true if output.include?("could not find codec parameters")
    end

    def valid?
      not @invalid
    end

    def width
      resolution.split("x")[0].to_i rescue nil
    end

    def height
      resolution.split("x")[1].to_i rescue nil
    end

    def calculated_aspect_ratio
      aspect_from_dar || aspect_from_dimensions
    end

    def size
      File.size(@path)
    end

    def audio_channels
      return nil unless @audio_channels
      return @audio_channels[/\d*/].to_i if @audio_channels["channels"]
      return 1 if @audio_channels["mono"]
      return 2 if @audio_channels["stereo"]
      return 6 if @audio_channels["5.1"]
    end

    def frame_rate
      return nil unless video_stream
      video_stream[/(\d*\.?\d*)\s?fps/] ? $1.to_f : nil
    end

    def transcode(output_file, options = EncodingOptions.new, transcoder_options = {}, &block)
      Transcoder.new(self, output_file, options, transcoder_options).run &block
    end

    def screenshot(output_file, options = EncodingOptions.new, transcoder_options = {}, &block)
      Transcoder.new(self, output_file, options.merge(screenshot: true), transcoder_options).run &block
    end

    protected
    def aspect_from_dar
      return nil unless dar
      w, h = dar.split(":")
      aspect = w.to_f / h.to_f
      aspect.zero? ? nil : aspect
    end

    def aspect_from_dimensions
      aspect = width.to_f / height.to_f
      aspect.nan? ? nil : aspect
    end

    def fix_encoding(output)
      output[/test/] # Running a regexp on the string throws error if it's not UTF-8
    rescue ArgumentError
      output.force_encoding("ISO-8859-1")
    end
  end
end
