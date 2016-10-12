require 'spec_helper.rb'

module FFMPEG
  describe Transcoder do
    let(:movie) { Movie.new("#{fixture_path}/movies/awesome movie.mov") }

    describe "initialization" do
      let(:output_path) { "#{tmp_path}/awesome.flv" }

      it "should accept EncodingOptions as options" do
        expect { Transcoder.new(movie, output_path, EncodingOptions.new) }.not_to raise_error
      end

      it "should accept Hash as options" do
        expect { Transcoder.new(movie, output_path, video_codec: "libx264") }.not_to raise_error
      end

      it 'should accept Array as options' do
        expect { Transcoder.new(movie, output_path, %w(-vcodec libx264)) }.not_to raise_error
      end

      it "should not accept anything else as options" do
        expect { Transcoder.new(movie, output_path, "string?") }.to raise_error(ArgumentError, /Unknown options format/)
      end
    end

    describe "transcoding" do
      context 'with default transcoder_options' do
        before do
          expect(FFMPEG.logger).to receive(:info).at_least(:once)
        end

        context "when ffmpeg freezes" do
          before do
            @original_timeout = Transcoder.timeout
            @original_ffmpeg_binary = FFMPEG.ffmpeg_binary

            Transcoder.timeout = 1
            FFMPEG.ffmpeg_binary = "#{fixture_path}/bin/ffmpeg-hanging"
          end

          it "should fail when the timeout is exceeded" do
            expect(FFMPEG.logger).to receive(:error)
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

          it 'should still work with (NTSC target)' do
            encoded = Transcoder.new(movie, "#{tmp_path}/awesome.mpg", target: 'ntsc-vcd').run
            expect(encoded.resolution).to eq('352x240')
          end

          after { Transcoder.timeout = @original_timeout }
        end

        it "should transcode the movie with progress given an awesome movie" do
          FileUtils.rm_f "#{tmp_path}/awesome.flv"

          transcoder = Transcoder.new(movie, "#{tmp_path}/awesome.flv")
          progress_updates = []
          transcoder.run { |progress| progress_updates << progress }
          expect(transcoder.encoded).to be_valid
          expect(progress_updates).to include(0.0, 1.0)
          expect(progress_updates.length).to be >= 3
          expect(File.exists?("#{tmp_path}/awesome.flv")).to be_truthy
        end

        it "should transcode the movie with EncodingOptions" do
          FileUtils.rm_f "#{tmp_path}/optionalized.mp4"

          options = {video_codec: "libx264", frame_rate: 10, resolution: "320x240", video_bitrate: 300,
                     audio_codec: "libmp3lame", audio_bitrate: 32, audio_sample_rate: 22050, audio_channels: 1}

          encoded = Transcoder.new(movie, "#{tmp_path}/optionalized.mp4", options).run
          expect(encoded.video_bitrate).to be_within(90000).of(300000)
          expect(encoded.video_codec).to match(/h264/)
          expect(encoded.resolution).to eq("320x240")
          expect(encoded.frame_rate).to eq(10.0)
          expect(encoded.audio_bitrate).to be_within(2000).of(32000)
          expect(encoded.audio_codec).to match(/mp3/)
          expect(encoded.audio_sample_rate).to eq(22050)
          expect(encoded.audio_channels).to eq(1)
        end

        context 'audio only' do
          let(:sound) { Movie.new("#{fixture_path}/sounds/hello.wav") }
          it 'should transcode without video' do
            FileUtils.rm_f "#{tmp_path}/hello.mp3"

            options = { audio_codec: "libmp3lame", custom: %w(-qscale:a 2)}

            encoded = Transcoder.new(sound, "#{tmp_path}/hello.mp3", options).run
            expect(encoded.video_codec).to be_nil
            expect(encoded.audio_codec).to match(/mp3/)
            expect(encoded.audio_sample_rate).to eq(44100)
            expect(encoded.audio_channels).to eq(1)
          end
        end

        context "with aspect ratio preservation" do
          before do
            @movie = Movie.new("#{fixture_path}/movies/awesome_widescreen.mov")
            @options = {resolution: "320x240"}
          end

          it "should work on width" do
            special_options = {preserve_aspect_ratio: :width}

            encoded = Transcoder.new(@movie, "#{tmp_path}/preserved_aspect.mp4", @options, special_options).run
            expect(encoded.resolution).to eq("320x180")
          end

          it "should work on height" do
            special_options = {preserve_aspect_ratio: :height}

            encoded = Transcoder.new(@movie, "#{tmp_path}/preserved_aspect.mp4", @options, special_options).run
            expect(encoded.resolution).to eq("426x240")
          end

          it "should not be used if original resolution is undeterminable" do
            expect(@movie).to receive(:calculated_aspect_ratio).and_return(nil)
            special_options = {preserve_aspect_ratio: :height}

            encoded = Transcoder.new(@movie, "#{tmp_path}/preserved_aspect.mp4", @options, special_options).run
            expect(encoded.resolution).to eq("320x240")
          end

          it "should round to resolutions divisible by 2" do
            expect(@movie).to receive(:calculated_aspect_ratio).at_least(:once).and_return(1.234)
            special_options = {preserve_aspect_ratio: :width}

            encoded = Transcoder.new(@movie, "#{tmp_path}/preserved_aspect.mp4", @options, special_options).run
            expect(encoded.resolution).to eq("320x260") # 320 / 1.234 should at first be rounded to 259
          end
        end

        it "should transcode the movie with String options" do
          FileUtils.rm_f "#{tmp_path}/string_optionalized.flv"

          encoded = Transcoder.new(movie, "#{tmp_path}/string_optionalized.flv", %w(-s 300x200 -ac 2)).run
          expect(encoded.resolution).to eq("300x200")
          expect(encoded.audio_channels).to eq(2)
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

        it 'should not crash on ISO-8859-1 characters' do
          FileUtils.rm_f "#{tmp_path}/saløndethé.flv"

          expect { Transcoder.new(movie, "#{tmp_path}/saløndethé.flv").run }.not_to raise_error
        end

        it "should fail when given an invalid movie" do
          expect(FFMPEG.logger).to receive(:error)
          movie = Movie.new(__FILE__)
          transcoder = Transcoder.new(movie, "#{tmp_path}/fail.flv")
          expect { transcoder.run }.to raise_error(FFMPEG::Error, /no output file created/)
        end

        it "should encode to the specified duration if given" do
          encoded = Transcoder.new(movie, "#{tmp_path}/durationalized.mp4", duration: 2).run

          expect(encoded.duration).to be >= 1.8
          expect(encoded.duration).to be <= 2.2
        end

        context "with remote URL as input" do
          before(:context) { start_web_server }
          after(:context) { stop_web_server }

          it "should transcode correctly" do
            movie = Movie.new("http://127.0.0.1:8000/awesome%20movie.mov")

            expect { Transcoder.new(movie, "#{tmp_path}/output.flv").run }.not_to raise_error
          end
        end

        context "with screenshot option" do
          it "should transcode to original movies resolution by default" do
            encoded = Transcoder.new(movie, "#{tmp_path}/image.jpg", screenshot: true).run
            expect(encoded.resolution).to eq("640x480")
          end

          it "should transcode absolute resolution if specified" do
            encoded = Transcoder.new(movie, "#{tmp_path}/image.bmp", screenshot: true, seek_time: 3, resolution: '400x200').run
            expect(encoded.resolution).to eq("400x200")
          end

          it "should be able to preserve aspect ratio" do
            encoded = Transcoder.new(movie, "#{tmp_path}/image.png", {screenshot: true, seek_time: 4, resolution: '320x500'}, preserve_aspect_ratio: :width).run
            expect(encoded.resolution).to eq("320x240")
          end

          describe 'for multiple screenshots' do
            context 'with output file validation' do
              it 'should fail' do
                expect { Transcoder.new(movie, "#{tmp_path}/invalid_%d.png", {screenshot: true, seek_time: 4, resolution: '320x500'}, preserve_aspect_ratio: :width).run }.to raise_error(FFMPEG::Error, /Failed encoding/)
              end
            end
            context 'without output file validation' do
              it 'should create sequential screenshots' do
                Transcoder.new(movie, "#{tmp_path}/screenshots_%d.png", {screenshot: true, seek_time: 4, resolution: '320x500'}, preserve_aspect_ratio: :width, validate: false).run
                expect(Dir[File.join(tmp_path, 'screenshots_*.png')].count { |file| File.file?(file) }).to eq(1)
              end
            end
          end
        end

        context "audio only" do
          before do
            @original_timeout = Transcoder.timeout
            @original_ffmpeg_binary = FFMPEG.ffmpeg_binary

            Transcoder.timeout = 1
            FFMPEG.ffmpeg_binary = "#{fixture_path}/bin/ffmpeg-audio-only"
          end

          it 'should fail when the timeout is exceeded' do
            transcoder = Transcoder.new(movie, "#{tmp_path}/timeout.mp4")
            expect { transcoder.run }.to raise_error(FFMPEG::Error, /Errors: no output file created/)
          end

          after do
            Transcoder.timeout = @original_timeout
            FFMPEG.ffmpeg_binary = @original_ffmpeg_binary
          end
        end
      end
    end

    describe 'watermarking' do
      context 'with default transcoder_options' do

        it 'should transcode the movie with the watermark' do
          options = { watermark: "#{fixture_path}/images/watermark.png", watermark_filter: { position: 'RB' }  }
          transcoder = Transcoder.new(movie, "#{tmp_path}/watermarked.mp4", options)
          expect { transcoder.run }.not_to raise_error
        end
      end
    end

    describe 'transcoding_options' do
      let(:transcoder) { Transcoder.new(movie, "#{tmp_path}/tmp.mp4", options, transcoding_options) }

      context 'with validate: false' do
        let(:options) { {} }
        let(:transcoding_options) { {validate: false} }

        before { allow(transcoder).to receive(:transcode_movie) }
        after { FileUtils.rm_f "#{tmp_path}/tmp.mp4" }

        it 'should not validate the movie output' do
          expect(transcoder).to_not receive(:validate_output_file)
          allow(transcoder).to receive(:encoded)
          transcoder.run
        end

        it 'should not return Movie object' do
          allow(transcoder).to receive(:validate_output_file)
          expect(transcoder).to_not receive(:encoded)
          expect(transcoder.run).to eq(nil)
        end
      end

      context 'with custom options' do
        let(:options) { {
            video_codec: 'libx264',
            custom: %w(-map 0:0 -map 0:1)
          } }
        let(:transcoding_options) { {} }

        it 'should not raise an error' do
          expect { transcoder.run }.to_not raise_error
        end

        it 'should add the custom options to the command' do
          expect(transcoder.command.join(' ')).to include('-map 0:0 -map 0:1')
        end
      end

      context 'with input' do
        let(:input_path) { 'path/img_%03d.gif' }

        context 'is a movie' do
          context 'and no input is specified' do
            let(:transcoder) { Transcoder.new(movie, 'tmp.mp4') }

            it "should use the movie's path" do
              expect(transcoder.input).to eq(movie.path)
            end

            it 'should add the input to the shell command' do
              expect(transcoder.command.join(' ')).to include(" -i #{transcoder.input}")
            end
          end

          context 'and an input is also specified' do
            let(:transcoder) { Transcoder.new(movie, 'tmp.mp4', {}, input: input_path) }

            it 'should use the provided input' do
              expect(transcoder.input).to eq(input_path)
            end
          end
        end

        context 'is a path spec' do
          let(:transcoder) { Transcoder.new(movie, 'tmp.mp4', {}, input: input_path) }

          it "should use the input path" do
            expect(transcoder.input).to eq(input_path)
          end
        end
      end

      context 'with input_options' do
        let(:option) { {framerate: '1/5'} }
        let(:transcoder) { Transcoder.new(movie, 'tmp.mp4', {}, input_options: option) }

        it 'should add the input_options before the input' do
          expect(transcoder.command.join(' ')).to include("-framerate 1/5 -i #{transcoder.input}")
        end

        context 'to create a slideshow' do
          let(:file_spec) { "#{fixture_path}/images/img_%03d.jpeg"}
          let(:output) { "#{tmp_path}/slideshow.mp4"}
          let(:transcoder) { Transcoder.new(movie, output, {}, input: file_spec, input_options: option) }

          it 'should add the input_options before the input' do
            expect(transcoder.command.join(' ')).to include("-framerate 1/5 -i #{file_spec}")
          end

          it 'should not raise an error' do
            expect { transcoder.run }.to_not raise_error
          end

          it 'should produce the slideshow' do
            encoded = transcoder.run
            expect(encoded.duration).to eq(25)
          end

          context 'with source files where file type name does not match the image type' do
            let(:file_spec) { "#{fixture_path}/images/wrong_type/img_%03d.tiff"}
            let(:output) { "#{tmp_path}/slideshow_fail.mp4"}

            it 'should raise an error' do
              expect { transcoder.run }.to raise_error(FFMPEG::Error, /encoded file is invalid/)
            end
          end

          context 'with no movie defined' do
            let(:movie) { nil }

            it 'should not raise an error' do
              expect { transcoder.run }.to_not raise_error
            end
          end

        end
      end
    end
  end
end
