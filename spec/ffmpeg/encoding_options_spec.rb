require 'spec_helper.rb'

module FFMPEG
  describe EncodingOptions do
    describe "ffmpeg arguments conversion" do
      it "should convert video codec" do
        expect(EncodingOptions.new(video_codec: "libx264").to_a).to eq(%w(-vcodec libx264))
      end

      it "should know the width from the resolution or be nil" do
        expect(EncodingOptions.new(resolution: "320x240").width).to eq(320)
        expect(EncodingOptions.new.width).to be_nil
      end

      it "should know the height from the resolution or be nil" do
        expect(EncodingOptions.new(resolution: "320x240").height).to eq(240)
        expect(EncodingOptions.new.height).to be_nil
      end

      it "should convert frame rate" do
        expect(EncodingOptions.new(frame_rate: 29.9).to_a).to eq(%w(-r 29.9))
      end

      it "should convert the resolution" do
        expect(EncodingOptions.new(resolution: "640x480").to_a).to include("-s", "640x480")
      end

      it "should add calculated aspect ratio" do
        expect(EncodingOptions.new(resolution: "640x480").to_a).to include("-aspect", "1.3333333333333333")
        expect(EncodingOptions.new(resolution: "640x360").to_a).to include("-aspect", "1.7777777777777777")
      end

      it "should use specified aspect ratio if given" do
        output = EncodingOptions.new(resolution: "640x480", aspect: 1.77777777777778).to_a
        expect(output).to include("-s", "640x480")
        expect(output).to include("-aspect", "1.77777777777778")
      end

      it "should convert video bitrate" do
        expect(EncodingOptions.new(video_bitrate: "600k").to_a).to eq(%w(-b:v 600k))
      end

      it "should use k unit for video bitrate" do
        expect(EncodingOptions.new(video_bitrate: 600).to_a).to eq(%w(-b:v 600k))
      end

      it "should convert audio codec" do
        expect(EncodingOptions.new(audio_codec: "aac").to_a).to eq( %w(-acodec aac))
      end

      it "should convert audio bitrate" do
        expect(EncodingOptions.new(audio_bitrate: "128k").to_a).to eq(%w(-b:a 128k))
      end

      it "should use k unit for audio bitrate" do
        expect(EncodingOptions.new(audio_bitrate: "128k").to_a).to eq(%w(-b:a 128k))
      end

      it "should convert audio sample rate" do
        expect(EncodingOptions.new(audio_sample_rate: 44100).to_a).to eq(%w(-ar 44100))
      end

      it "should convert audio channels" do
        expect(EncodingOptions.new(audio_channels: 2).to_a).to eq(%w(-ac 2))
      end

      it "should convert maximum video bitrate" do
        expect(EncodingOptions.new(video_max_bitrate: 600).to_a).to eq(%w(-maxrate 600k))
      end

      it "should convert minimum video bitrate" do
        expect(EncodingOptions.new(video_min_bitrate: 600).to_a).to eq(%w(-minrate 600k))
      end

      it "should convert video bitrate tolerance" do
        expect(EncodingOptions.new(video_bitrate_tolerance: 100).to_a).to eq(%w(-bt 100k))
      end

      it "should convert buffer size" do
        expect(EncodingOptions.new(buffer_size: 2000).to_a).to eq(%w(-bufsize 2000k))
      end

      it "should convert threads" do
        expect(EncodingOptions.new(threads: 2).to_a).to eq(%w(-threads 2))
      end

      it "should convert duration" do
        expect(EncodingOptions.new(duration: 30).to_a).to eq(%w(-t 30))
      end

      it "should convert target" do
        expect(EncodingOptions.new(target: 'ntsc-vcd').to_a).to eq(%w(-target ntsc-vcd))
      end

      it "should convert keyframe interval" do
        expect(EncodingOptions.new(keyframe_interval: 60).to_a).to eq(%w(-g 60))
      end

      it "should convert video preset" do
        expect(EncodingOptions.new(video_preset: "max").to_a).to eq(%w(-vpre max))
      end

      it "should convert audio preset" do
        expect(EncodingOptions.new(audio_preset: "max").to_a).to eq(%w(-apre max))
      end

      it "should convert file preset" do
        expect(EncodingOptions.new(file_preset: "max.ffpreset").to_a).to eq(%w(-fpre max.ffpreset))
      end

      it "should specify seek time" do
        expect(EncodingOptions.new(seek_time: 1).to_a).to eq(%w(-ss 1))
      end

      it "should specify default screenshot parameters" do
        expect(EncodingOptions.new(screenshot: true).to_a).to eq(%w(-vframes 1 -f image2))
      end

      it 'should specify screenshot parameters when using -vframes' do
        expect(EncodingOptions.new(screenshot: true, vframes: 123).to_a).to eq(%w(-f image2 -vframes 123))
      end

      it 'should specify screenshot parameters when using video quality -v:q' do
        expect(EncodingOptions.new(screenshot: true, vframes: 123, quality: 3).to_a).to eq(%w(-f image2 -vframes 123 -q:v 3))
      end

      it 'should put the parameters in order of codecs, presets, others' do
        opts = Hash.new
        opts[:frame_rate] = 25
        opts[:video_codec] = 'libx264'
        opts[:video_preset] = 'normal'
        opts[:watermark_filter] = { position: "RT", padding_x: 10, padding_y: 10}
        opts[:watermark] = 'watermark.png'

        converted = EncodingOptions.new(opts).to_a
        expect(converted).to eq(%w(-i watermark.png -filter_complex scale=,overlay=x=main_w-overlay_w-10:y=10 -vcodec libx264 -vpre normal -r 25))
      end

      it "should convert a lot of them simultaneously" do
        converted = EncodingOptions.new(video_codec: "libx264", audio_codec: "aac", video_bitrate: "1000k").to_a
        expect(converted).to include('-acodec', 'aac')
      end

      it "should ignore options with nil value" do
        expect(EncodingOptions.new(video_codec: "libx264", frame_rate: nil).to_a).to eq(%w(-vcodec libx264))
      end

      it "should convert x264 vprofile" do
        expect(EncodingOptions.new(x264_vprofile: "high").to_a).to eq(%w(-vprofile high))
      end

      it "should convert x264 preset" do
        expect(EncodingOptions.new(x264_preset: "slow").to_a).to eq(%w(-preset slow))
      end

      it "should specify input watermark file" do
        expect(EncodingOptions.new(watermark: "watermark.png").to_a).to eq(%w(-i watermark.png))
      end

      it "should specify watermark position at left top corner" do
        opts = Hash.new
        opts[:resolution] = "640x480"
        opts[:watermark_filter] = { position: "LT", padding_x: 10, padding_y: 10 }
        converted = EncodingOptions.new(opts).to_a
        expect(converted).to include "-filter_complex", 'scale=640x480,overlay=x=10:y=10'
      end

      it 'should specify watermark position at right top corner' do
        opts = {
            resolution: '640x480',
            watermark_filter: { position: 'RT', padding_x: 10, padding_y: 10 }
        }
        converted = EncodingOptions.new(opts).to_a
        expect(converted).to include "-filter_complex", 'scale=640x480,overlay=x=main_w-overlay_w-10:y=10'
      end

      it 'should specify watermark position at left bottom corner' do
        opts = {
            resolution: '640x480',
            watermark_filter: { position: 'LB', padding_x: 10, padding_y: 10 }
        }
        converted = EncodingOptions.new(opts).to_a
        expect(converted).to include "-filter_complex", 'scale=640x480,overlay=x=10:y=main_h-overlay_h-10'
      end

      it "should specify watermark position at left bottom corner" do
        opts = {
            resolution: '640x480',
            watermark_filter: { position: 'RB', padding_x: 10, padding_y: 10 }
        }
        converted = EncodingOptions.new(opts).to_a
        expect(converted.find{|str| str =~ /overlay/ }).to include "overlay=x=main_w-overlay_w-10:y=main_h-overlay_h-10"
      end

      context 'for custom options' do
        it 'should not allow custom options as String' do
          expect { EncodingOptions.new({ custom: '-map 0:0 -map 0:1' }).to_a }.to raise_error(ArgumentError)
        end

        it 'should correctly include custom options' do
          converted = EncodingOptions.new({ custom: %w(-map 0:0 -map 0:1) }).to_a
          expect(converted).to eq(['-map', '0:0', '-map', '0:1'])
        end
      end
    end
  end
end
