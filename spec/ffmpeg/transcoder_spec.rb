require 'spec_helper.rb'

module FFMPEG
  describe Transcoder do
    let(:movie) { Movie.new("#{fixture_path}/movies/awesome movie.mov") }

    describe "initialization" do
      let(:output_path) { "#{tmp_path}/awesome.flv" }

      it "should accept EncodingOptions as options" do
        expect { Transcoder.new(movie, output_path, EncodingOptions.new) }.not_to raise_error(ArgumentError)
      end

      it "should accept Hash as options" do
        expect { Transcoder.new(movie, output_path, video_codec: "libx264") }.not_to raise_error(ArgumentError)
      end

      it "should accept String as options" do
        expect { Transcoder.new(movie, output_path, "-vcodec libx264") }.not_to raise_error(ArgumentError)
      end

      it "should not accept anything else as options" do
        expect { Transcoder.new(movie, output_path, ["array?"]) }.to raise_error(ArgumentError, /Unknown options format/)
      end
    end

    describe "transcoding" do
      before do
        FFMPEG.logger.should_receive(:info).at_least(:once)
      end

      context "when ffmpeg freezes" do
        before do
          @original_timeout = Transcoder.timeout
          @original_ffmpeg_binary = FFMPEG.ffmpeg_binary

          Transcoder.timeout = 1
          FFMPEG.ffmpeg_binary = "#{fixture_path}/bin/ffmpeg-hanging"
        end

        it "should fail when the timeout is exceeded" do
          FFMPEG.logger.should_receive(:error)
          transcoder = Transcoder.new(movie, "#{tmp_path}/timeout.mp4")
          expect { transcoder.run }.to raise_error(FFMPEG::Error, /Process hung/)
        end

        after do
          Transcoder.timeout = @original_timeout
          FFMPEG.ffmpeg_binary = @original_ffmpeg_binary
        end
      end

      context "with timeout disabled" do
        before do
          @original_timeout = Transcoder.timeout
          Transcoder.timeout = false
        end

        it "should still work" do
          encoded = Transcoder.new(movie, "#{tmp_path}/awesome.mpg").run
          encoded.resolution.should == "640x480"
        end

        after { Transcoder.timeout = @original_timeout }
      end

      it "should transcode the movie with progress given an awesome movie" do
        FileUtils.rm_f "#{tmp_path}/awesome.flv"

        transcoder = Transcoder.new(movie, "#{tmp_path}/awesome.flv")
        progress_updates = []
        transcoder.run { |progress| progress_updates << progress }
        transcoder.encoded.should be_valid
        progress_updates.should include(0.0, 1.0)
        progress_updates.length.should >= 3
        File.exists?("#{tmp_path}/awesome.flv").should be_true
      end

      it "should transcode the movie with EncodingOptions" do
        FileUtils.rm_f "#{tmp_path}/optionalized.mp4"

        options = {video_codec: "libx264", frame_rate: 10, resolution: "320x240", video_bitrate: 300,
                   audio_codec: "libfaac", audio_bitrate: 32, audio_sample_rate: 22050, audio_channels: 1}

        encoded = Transcoder.new(movie, "#{tmp_path}/optionalized.mp4", options).run
        encoded.video_bitrate.should be_within(90).of(300)
        encoded.video_codec.should =~ /h264/
        encoded.resolution.should == "320x240"
        encoded.frame_rate.should == 10.0
        encoded.audio_bitrate.should be_within(2).of(32)
        encoded.audio_codec.should =~ /aac/
        encoded.audio_sample_rate.should == 22050
        encoded.audio_channels.should == 1
      end

      context "with aspect ratio preservation" do
        before do
          @movie = Movie.new("#{fixture_path}/movies/awesome_widescreen.mov")
          @options = {resolution: "320x240"}
        end

        it "should work on width" do
          special_options = {preserve_aspect_ratio: :width}

          encoded = Transcoder.new(@movie, "#{tmp_path}/preserved_aspect.mp4", @options, special_options).run
          encoded.resolution.should == "320x180"
        end

        it "should work on height" do
          special_options = {preserve_aspect_ratio: :height}

          encoded = Transcoder.new(@movie, "#{tmp_path}/preserved_aspect.mp4", @options, special_options).run
          encoded.resolution.should == "426x240"
        end

        it "should not be used if original resolution is undeterminable" do
          @movie.should_receive(:calculated_aspect_ratio).and_return(nil)
          special_options = {preserve_aspect_ratio: :height}

          encoded = Transcoder.new(@movie, "#{tmp_path}/preserved_aspect.mp4", @options, special_options).run
          encoded.resolution.should == "320x240"
        end

        it "should round to resolutions divisible by 2" do
          @movie.should_receive(:calculated_aspect_ratio).at_least(:once).and_return(1.234)
          special_options = {preserve_aspect_ratio: :width}

          encoded = Transcoder.new(@movie, "#{tmp_path}/preserved_aspect.mp4", @options, special_options).run
          encoded.resolution.should == "320x260" # 320 / 1.234 should at first be rounded to 259
        end
      end

      it "should transcode the movie with String options" do
        FileUtils.rm_f "#{tmp_path}/string_optionalized.flv"

        encoded = Transcoder.new(movie, "#{tmp_path}/string_optionalized.flv", "-s 300x200 -ac 2").run
        encoded.resolution.should == "300x200"
        encoded.audio_channels.should == 2
      end

      it "should transcode the movie which name include single quotation mark" do
        FileUtils.rm_f "#{tmp_path}/output.flv"

        movie = Movie.new("#{fixture_path}/movies/awesome'movie.mov")

        expect { Transcoder.new(movie, "#{tmp_path}/output.flv").run }.not_to raise_error
      end

      it "should transcode when output filename includes single quotation mark" do
        FileUtils.rm_f "#{tmp_path}/output with 'quote.flv"

        expect { Transcoder.new(movie, "#{tmp_path}/output with 'quote.flv").run }.not_to raise_error
      end

      pending "should not crash on ISO-8859-1 characters (dont know how to spec this)"

      it "should fail when given an invalid movie" do
        FFMPEG.logger.should_receive(:error)
        movie = Movie.new(__FILE__)
        transcoder = Transcoder.new(movie, "#{tmp_path}/fail.flv")
        expect { transcoder.run }.to raise_error(FFMPEG::Error, /no output file created/)
      end

      it "should encode to the specified duration if given" do
        encoded = Transcoder.new(movie, "#{tmp_path}/durationalized.mp4", duration: 2).run

        encoded.duration.should >= 1.8
        encoded.duration.should <= 2.2
      end

      context "with screenshot option" do
        it "should transcode to original movies resolution by default" do
          encoded = Transcoder.new(movie, "#{tmp_path}/image.jpg", screenshot: true).run
          encoded.resolution.should == "640x480"
        end

        it "should transcode absolute resolution if specified" do
          encoded = Transcoder.new(movie, "#{tmp_path}/image.bmp", screenshot: true, seek_time: 3, resolution: '400x200').run
          encoded.resolution.should == "400x200"
        end

        it "should be able to preserve aspect ratio" do
          encoded = Transcoder.new(movie, "#{tmp_path}/image.png", {screenshot: true, seek_time: 4, resolution: '320x500'}, preserve_aspect_ratio: :width).run
          encoded.resolution.should == "320x240"
        end
      end

      context "audio only" do
        before do
          @original_timeout = Transcoder.timeout
          @original_ffmpeg_binary = FFMPEG.ffmpeg_binary

          Transcoder.timeout = 1
          FFMPEG.ffmpeg_binary = "#{fixture_path}/bin/ffmpeg-audio-only"
        end

        it "should not fail when the timeout is exceeded" do
          transcoder = Transcoder.new(movie, "#{tmp_path}/timeout.mp4")
          expect { transcoder.run }.not_to raise_error(FFMPEG::Error, /Process hung/)
        end

        after do
          Transcoder.timeout = @original_timeout
          FFMPEG.ffmpeg_binary = @original_ffmpeg_binary
        end
      end

    end

    describe "#run" do
      it "should call for #transcode_movie, #validate_output_file and #encoded methods" do
        transcoder = Transcoder.new(movie, "#{tmp_path}/output.flv")
        transcoder.should_receive(:transcode_movie).and_return(transcoder)
        transcoder.should_receive(:validate_output_file).and_return(true)
        transcoder.should_receive(:encoded).and_return(movie)
        transcoder.run
      end
    end

  end
end
