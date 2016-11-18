require 'spec_helper.rb'
require 'net/http'
require 'webrick'

module FFMPEG
  describe Movie do
    describe "initializing" do
      let(:fake_output) { StringIO.new(File.read("#{fixture_path}/outputs/#{fixture_file}")) }
      let(:movie) do
        allow(Open3).to receive(:popen3).and_yield(nil, nil, fake_output)
        Movie.new(__FILE__)
      end

      context "given a non existing file" do
        let(:movie) { Movie.new('i_dont_exist') }

        it "should throw ArgumentError" do
          expect { movie }.to raise_error(Errno::ENOENT, /does not exist/)
        end
      end

      context "given a file containing a single quotation mark in the filename" do
        let(:movie) { Movie.new("#{fixture_path}/movies/awesome'movie.mov") }

        it "should run ffmpeg successfully" do
          expect(movie.duration).to be_within(0.01).of(7.56)
          expect(movie.frame_rate).to be_within(0.01).of(16.75)
        end
      end

      context "given a URL" do
        before(:context) { start_web_server }
        after(:context) { stop_web_server }
        context "that is correct" do

          let(:movie) { Movie.new("http://127.0.0.1:8000/awesome%20movie.mov") }

          it "should be valid" do
            expect(movie).to be_valid
          end

          it "should know the file size" do
            expect(movie.size).to eq(455546)
          end

          it "should remember the movie URL" do
            expect(movie.path).to eq("http://127.0.0.1:8000/awesome%20movie.mov")
          end

          it "should be marked as remote" do
            expect(movie.remote?).to be_truthy
          end

          context 'with a query string' do
            # We're mocking this to fail on the same URL with the query string added.
            # This means that we're passing the query string through using .request_uri
            # rather than .path

            it 'should not be found' do
              expect { Movie.new('http://127.0.0.1:8000/awesome%20movie.mov?fail=1') }.to raise_error(Errno::ENOENT)
            end
          end
        end
        context "that does not exist" do
          it "should raise an exception" do
            expect { Movie.new("http://127.0.0.1:8000/awesome%20movie_missing.mov") }.to raise_error(Errno::ENOENT)
          end
        end
        context 'that redirects' do
          context 'to a remote uri' do
            let(:movie) { Movie.new('http://www.redirect-example.com/moved_movie.mov') }

            it "should know the file size" do
              expect(movie.size).to eq(455_546)
            end
          end
          context 'to a relative uri' do
            let(:movie) { Movie.new('http://127.0.0.1:8000/deep_path/awesome%20movie.mov') }

            it 'should know the file size' do
              expect(movie.size).to eq(455_546)
            end
          end
          context 'to a relative uri respecting redirect limits' do
            before { FFMPEG.max_http_redirect_attempts = 0 }
            after { FFMPEG.max_http_redirect_attempts = nil }

            it 'raise FFMPEG::HTTPTooManyRequests' do
              expect { Movie.new('http://127.0.0.1:8000/deep_path/awesome%20movie.mov') }.to raise_error(FFMPEG::HTTPTooManyRequests)
            end
          end

          context 'to a relative uri with too many redirects' do
            it 'should know the file size' do
              expect { Movie.new('http://www.toomany-redirects-example.com/moved_movie.mov') }.to raise_error(FFMPEG::HTTPTooManyRequests)
            end
          end
        end
      end

      context "given a non movie file" do
        let(:movie) { Movie.new(__FILE__) }

        it "should not be valid" do
          expect(movie).to_not be_valid
        end

        it "should have a duration of 0" do
          expect(movie.duration).to eq(0)
        end

        it "should have nil height" do
          expect(movie.height).to be_nil
        end

        it "should have nil width" do
          expect(movie.width).to be_nil
        end

        it "should have nil frame_rate" do
          expect(movie.frame_rate).to be_nil
        end
      end

      context "given an empty flv file (could not find codec parameters)" do
        let(:movie) { Movie.new("#{fixture_path}/movies/empty.flv") }

        it "should not be valid" do
          expect(movie).to_not be_valid
        end
      end

      context "given an ios mobile video filmed without rotation" do
        let(:movie) { Movie.new("#{fixture_path}/movies/ios_rotate0.mov") }

        it "should have correct rotation detected" do
          expect(movie.rotation).to eq(nil)
        end
        it "should have untouched width and height" do
          expect(movie.width).to eq(1920)
          expect(movie.height).to eq(1080)
        end
      end

      context "given an ios mobile video filmed with rotation=90" do
        let(:movie) { Movie.new("#{fixture_path}/movies/ios_rotate90.mov") }

        it "should have correct rotation detected" do
          expect(movie.rotation).to eq(90)
        end

        it "should have switched width and height" do
          expect(movie.width).to eq(1080)
          expect(movie.height).to eq(1920)
        end
      end

      context "given an ios mobile video filmed with rotation=180" do
        let(:movie) { Movie.new("#{fixture_path}/movies/ios_rotate180.mov") }

        it "should have correct rotation detected" do
          expect(movie.rotation).to eq(180)
        end
        it "should have untouched width and height" do
          expect(movie.width).to eq(1920)
          expect(movie.height).to eq(1080)
        end
      end

      context "given an ios mobile video filmed with rotation=270" do
        let(:movie) { Movie.new("#{fixture_path}/movies/ios_rotate270.mov") }

        it "should have correct rotation detected" do
          expect(movie.rotation).to eq(270)
        end
        it "should have switched width and height" do
          expect(movie.width).to eq(1080)
          expect(movie.height).to eq(1920)
        end
      end

      context "given an ios9 mov file (with superfluous data streams)" do
        let(:movie) { Movie.new("#{fixture_path}/movies/ios9.mov") }

        it "should be valid" do
          expect(movie).to be_valid
        end
      end

      context "given a broken mp4 file" do
        let(:movie) { Movie.new("#{fixture_path}/movies/broken.mp4") }

        it "should not be valid" do
          expect(movie).to_not be_valid
        end

        it "should have nil calculated_aspect_ratio" do
          expect(movie.calculated_aspect_ratio).to be_nil
        end
      end

      context "given a file with data streams" do
        let(:movie) { Movie.new("#{fixture_path}/movies/file_with_data_streams.mp4") }

        it "should be valid" do
          expect(movie).to be_valid
        end
      end

      context "given a file named with URL characters" do
        let(:movie) { Movie.new("#{fixture_path}/movies/file+with+data&streams=works?.mp4") }

        it "should be valid" do
          expect(movie).to be_valid
        end
      end

      context "given a weird aspect ratio file" do
        let(:movie) { Movie.new("#{fixture_path}/movies/weird_aspect.small.mpg") }

        it "should parse the DAR" do
          expect(movie.dar).to eq("704:405")
        end

        it "should have correct calculated_aspect_ratio" do
          expect(movie.calculated_aspect_ratio.to_s[0..14]).to eq("1.7382716049382") # substringed to be 1.9 compatible
        end
      end

      describe 'Special cases: ' do
        let(:movie) do
          allow(Open3).to receive(:popen3).and_yield(nil,fake_output,nil)
          Movie.new(__FILE__)
        end

        context "given a file with bad JSON" do
          let(:fixture_file) { 'file_with_bad_json.txt' }

          it 'should raise an exception' do
            expect { movie }.to raise_error RuntimeError, /Could not parse output from FFProbe/
          end
        end

        context "given an impossible DAR" do
          let(:fixture_file) { 'file_with_weird_dar.txt' }

          it "should parse the DAR" do
            expect(movie.dar).to eq('0:1')
          end

          it "should calculate using width and height instead" do
            expect(movie.calculated_aspect_ratio.to_s[0..14]).to eq("1.7777777777777") # substringed to be 1.9 compatible
          end

          context 'when width/height is flipped' do
            before { movie.instance_variable_set :@rotation, 90 }
            it "should calculate using width and height instead" do
              expect(movie.calculated_aspect_ratio).to eq(0.5625)
            end
          end
        end

        context 'given an impossible SAR' do
          let(:fixture_file) { 'file_with_weird_sar.txt' }

          it 'should parse the SAR' do
            expect(movie.sar).to eq('0:1')
          end

          it 'should using square SAR, 1.0 instead' do
            expect(movie.calculated_pixel_aspect_ratio.to_s[0..14]).to eq('1') # substringed to be 1.9 compatible
          end

          context 'when width/height is flipped' do
            before { movie.instance_variable_set :@rotation, 90 }
            it 'should using square SAR, 1.0 instead' do
              expect(movie.calculated_pixel_aspect_ratio).to eq(1)
            end
          end
        end

        context "given a file with ISO-8859-1 characters in output" do
          let(:fixture_file) { 'file_with_iso-8859-1.txt' }

          it "should not crash" do
            expect { movie }.to_not raise_error
          end
        end

        context "given a file with 5.1 audio" do
          let(:fixture_file) { 'file_with_surround_sound.txt' }

          it "should have 6 audio channels" do
            expect(movie.audio_channels).to eq(6)
          end
        end

        context "given a file with no audio" do
          let(:fixture_file) { 'file_with_no_audio.txt' }

          it "should have nil audio channels" do
            expect(movie.audio_channels).to eq(nil)
          end
        end

        context "given a file with non supported audio" do
          let(:fixture_file) { 'file_with_non_supported_audio_stdout.txt' }
          let(:movie) do
            fake_stderr = StringIO.new(File.read("#{fixture_path}/outputs/file_with_non_supported_audio_stderr.txt"))
            allow(Open3).to receive(:popen3).and_yield(nil,fake_output,fake_stderr)
            Movie.new(__FILE__)
          end

          it "should be valid" do
            expect(movie).to be_valid
          end
        end

        context "given a file with non supported audio and video" do
          let(:fixture_file) { 'file_with_non_supported_audio_and_video_stdout.txt' }
          let(:movie) do
            fake_stderr = StringIO.new(File.read("#{fixture_path}/outputs/file_with_non_supported_audio_and_video_stderr.txt"))
            allow(Open3).to receive(:popen3).and_yield(nil, fake_output, fake_stderr)
            Movie.new(__FILE__)
          end

          it "should not be valid" do
            expect(movie).to_not be_valid
          end
        end

      end

      context 'given a file with improperly formatted creation_time' do
        let(:movie) { Movie.new("#{fixture_path}/sounds/bad_metadata_creation_time.wav") }

        it 'should set creation_time to nil' do
          expect(movie.creation_time).to be_nil
        end
      end

      context "given a weird storage/pixel aspect ratio file" do
        let(:movie) { Movie.new("#{fixture_path}/movies/weird_aspect.small.mpg") }

        it "should parse the SAR" do
          expect(movie.sar).to eq("64:45")
        end

        it "should have correct calculated_pixel_aspect_ratio" do
          expect(movie.calculated_pixel_aspect_ratio.to_s[0..14]).to eq("1.4222222222222") # substringed to be 1.9 compatible
        end
      end

      context "given an awesome movie file" do
        let(:movie) { Movie.new("#{fixture_path}/movies/awesome movie.mov") }

        it 'exposes the format tags' do
          expect(movie.format_tags.keys).to include(:major_brand, :minor_version, :compatible_brands, :creation_time)
        end

        it 'exposes the metadata' do
          expect(movie.metadata.keys).to include(:streams, :format)
        end

        it "should remember the movie path" do
          expect(movie.path).to eq("#{fixture_path}/movies/awesome movie.mov")
        end

        it "should be marked as local" do
          expect(movie.local?).to be_truthy
        end

        it "should parse duration to number of seconds" do
          expect(movie.duration).to be_within(0.01).of(7.56)
        end

        it "should parse the bitrate" do
          expect(movie.bitrate).to eq(481846)
        end

        it "should return nil rotation when no rotation exists" do
          expect(movie.rotation).to eq(nil)
        end

        it "should parse the creation_time" do
          expect(movie.creation_time).to eq(Time.parse("2010-02-05 16:05:04"))
        end

        it "should parse video stream information" do
          expect(movie.video_stream).to eq("h264 (Main) (avc1 / 0x31637661), yuv420p, 640x480 [SAR 1:1 DAR 4:3]")
        end

        it "should know the video codec" do
          expect(movie.video_codec).to match(/h264/)
        end

        it "should know the colorspace" do
          expect(movie.colorspace).to eq("yuv420p")
        end

        it "should know the resolution" do
          expect(movie.resolution).to eq("640x480")
        end

        it "should know the video bitrate" do
          expect(movie.video_bitrate).to eq(371185)
        end

        it "should know the width and height" do
          expect(movie.width).to eq(640)
          expect(movie.height).to eq(480)
        end

        it "should know the framerate" do
          expect(movie.frame_rate).to be_within(0.01).of(16.75)
        end

        it "should parse audio stream information" do
          expect(movie.audio_stream).to eq("aac (mp4a / 0x6134706d), 44100 Hz, stereo, fltp, 75832 bit/s")
        end

        it "should know the audio codec" do
          expect(movie.audio_codec).to match(/aac/)
        end

        it "should know the sample rate" do
          expect(movie.audio_sample_rate).to eq(44100)
        end

        it "should know the number of audio channels" do
          expect(movie.audio_channels).to eq(2)
        end

        it "should know the audio bitrate" do
          expect(movie.audio_bitrate).to eq(75832)
        end

        it "should be valid" do
          expect(movie).to be_valid
        end

        it "should calculate the aspect ratio" do
          expect(movie.calculated_aspect_ratio.to_s[0..14]).to eq("1.3333333333333") # substringed to be 1.9 compatible
        end

        it "should know the file size" do
          expect(movie.size).to eq(455546)
        end

        it "should know the container" do
          expect(movie.container).to eq("mov,mp4,m4a,3gp,3g2,mj2")
        end
      end

      context "given a movie file with 2 audio streams" do
        let(:movie) { Movie.new("#{fixture_path}/movies/multi_audio_movie.mp4") }

        it "should identify both audio streams" do
          expect(movie.audio_streams.length).to eq(2)
        end

        it "should assign audio_channels to the properties of the first stream" do
          audio_channels = movie.audio_streams[0][:channels]
          expect(movie.audio_channels).to eq audio_channels
        end

        it "should assign audio_codec to the properties of the first stream" do
          audio_codec = movie.audio_streams[0][:codec_name]
          expect(movie.audio_codec).to eq audio_codec
        end

        it "should assign audio_bitrate to the properties of the first stream" do
          audio_bitrate = movie.audio_streams[0][:bitrate]
          expect(movie.audio_bitrate).to eq audio_bitrate
        end

        it "should assign audio_channel_layout to the properties of the first stream" do
          audio_channel_layout = movie.audio_streams[0][:channel_layout]
          expect(movie.audio_channel_layout).to eq audio_channel_layout
        end

        it "should assign audio_tags to the properties of the first stream" do
          audio_tags = movie.audio_streams[0][:tags]
          expect(movie.audio_tags).to eq audio_tags
        end

        it "should assign audio_stream to the properties of the first stream" do
          stream_overview = movie.audio_streams[0][:overview]
          expect(movie.audio_stream).to eq stream_overview
        end
      end
    end

    context "given a rotated movie file" do
      let(:movie) { Movie.new("#{fixture_path}/movies/sideways movie.mov") }

      it "should parse the rotation" do
        expect(movie.rotation).to eq(90)
      end
    end

    describe "transcode" do
      let(:movie) { Movie.new("#{fixture_path}/movies/awesome movie.mov")}

      it "should run the transcoder" do

        transcoder_double = double(Transcoder)
        expect(Transcoder).to receive(:new).
          with(movie, "#{tmp_path}/awesome.flv", {custom: "-vcodec libx264"}, preserve_aspect_ratio: :width).
          and_return(transcoder_double)
        expect(transcoder_double).to receive(:run)

        movie.transcode("#{tmp_path}/awesome.flv", {custom: "-vcodec libx264"}, preserve_aspect_ratio: :width)
      end
    end

    describe "transcode" do
      let(:movie) { Movie.new("#{fixture_path}/movies/awesome movie.mov")}

      it "should run the transcoder" do

        transcoder_double = double(Transcoder)
        expect(Transcoder).to receive(:new).
            with(movie, "#{tmp_path}/awesome.flv", {custom: "-vcodec libx264"}, preserve_aspect_ratio: :width).
            and_return(transcoder_double)
        expect(transcoder_double).to receive(:run)

        movie.transcode("#{tmp_path}/awesome.flv", {custom: "-vcodec libx264"}, preserve_aspect_ratio: :width)
      end
    end

    describe 'transcode sound only' do
      let(:movie) { Movie.new("#{fixture_path}/sounds/hello.wav")}

      it "should run the transcoder" do

        transcoder_double = double(Transcoder)
        expect(Transcoder).to receive(:new).
            with(movie, "#{tmp_path}/hello.mp3", {audio_codec: 'libmp3lame', custom: %w(-qscale:a 2)}, {}).
            and_return(transcoder_double)
        expect(transcoder_double).to receive(:run)

        movie.transcode("#{tmp_path}/hello.mp3", {audio_codec: 'libmp3lame', custom: %w(-qscale:a 2)}, {})
      end
    end

    describe "screenshot" do
      let(:movie) { Movie.new("#{fixture_path}/movies/awesome movie.mov")}

      it "should run the transcoder with screenshot option" do

        transcoder_double = double(Transcoder)
        expect(Transcoder).to receive(:new).
          with(movie, "#{tmp_path}/awesome.jpg", {seek_time: 2, dimensions: "640x480", screenshot: true}, preserve_aspect_ratio: :width).
          and_return(transcoder_double)
        expect(transcoder_double).to receive(:run)

        movie.screenshot("#{tmp_path}/awesome.jpg", {seek_time: 2, dimensions: "640x480"}, preserve_aspect_ratio: :width)
      end

      context 'with wildcard output filename' do
        it 'should create multiple screenshots' do

          transcoder_double = double(Transcoder)
          expect(Transcoder).to receive(:new).
              with(movie, "#{tmp_path}/awesome_%d.jpg", {seek_time: 2, dimensions: '640x480', screenshot: true, vframes: 20}, preserve_aspect_ratio: :width, validate: false).
              and_return(transcoder_double)
          expect(transcoder_double).to receive(:run)

          movie.screenshot("#{tmp_path}/awesome_%d.jpg", {seek_time: 2, dimensions: '640x480', vframes: 20}, preserve_aspect_ratio: :width, validate: false)
        end
      end
    end
  end
end
