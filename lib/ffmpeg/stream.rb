module FFMPEG
  class Stream
    attr_reader :input_number, :stream_number, :language, :type
    attr_reader :video_codec, :video_bitrate, :colorspace, :resolution, :dar
    attr_reader :audio_channels, :audio_codec, :audio_bitrate, :audio_sample_rate
    attr_reader :subtitle_codec, :subtitle_format

    private

      attr_writer :input_number, :stream_number, :language, :type
      attr_writer :video_codec, :video_bitrate, :colorspace, :resolution, :dar
      attr_writer :audio_channels, :audio_codec, :audio_bitrate, :audio_sample_rate
      attr_writer :subtitle_codec, :subtitle_format
  end
end