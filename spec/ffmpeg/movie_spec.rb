require 'spec_helper.rb'

module FFMPEG
  describe Movie do
    describe "initializing" do
      let(:fake_output) { StringIO.new(File.read("#{fixture_path}/outputs/#{fixture_file}")) }
      let(:movie) do
        Open3.stub(:popen3).and_yield(nil, nil, fake_output)
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

      context "given a non movie file" do
        let(:movie) { Movie.new(__FILE__) }

        it "should not be valid" do
          movie.should_not be_valid
        end

        it "should have a duration of 0" do
          movie.duration.should == 0
        end

        it "should have nil height" do
          movie.height.should be_nil
        end

        it "should have nil width" do
          movie.width.should be_nil
        end

        it "should have nil frame_rate" do
          movie.frame_rate.should be_nil
        end
      end

      context "given an empty flv file (could not find codec parameters)" do
        let(:movie) { Movie.new("#{fixture_path}/movies/empty.flv") }

        it "should not be valid" do
          movie.should_not be_valid
        end
      end

      context "given an ios mobile video filmed without rotation" do
        let(:movie) { Movie.new("#{fixture_path}/movies/ios_rotate0.mov") }

        it "should have correct rotation detected" do
          movie.rotation.should == nil
        end
        it "should have untouched width and height" do
          movie.width.should == 1920
          movie.height.should == 1080
        end
      end

      context "given an ios mobile video filmed with rotation=90" do
        let(:movie) { Movie.new("#{fixture_path}/movies/ios_rotate90.mov") }

        it "should have correct rotation detected" do
          movie.rotation.should == 90
        end

        it "should have switched width and height" do
          movie.width.should == 1080
          movie.height.should == 1920
        end
      end

      context "given an ios mobile video filmed with rotation=180" do
        let(:movie) { Movie.new("#{fixture_path}/movies/ios_rotate180.mov") }

        it "should have correct rotation detected" do
          movie.rotation.should == 180
        end
        it "should have untouched width and height" do
          movie.width.should == 1920
          movie.height.should == 1080
        end
      end

      context "given an ios mobile video filmed with rotation=270" do
        let(:movie) { Movie.new("#{fixture_path}/movies/ios_rotate270.mov") }

        it "should have correct rotation detected" do
          movie.rotation.should == 270
        end
        it "should have switched width and height" do
          movie.width.should == 1080
          movie.height.should == 1920
        end
      end

      context "given an ios9 mov file (with superfluous data streams)" do
        let(:movie) { Movie.new("#{fixture_path}/movies/ios9.mov") }

        it "should be valid" do
          movie.should be_valid
        end
      end

      context "given a broken mp4 file" do
        let(:movie) { Movie.new("#{fixture_path}/movies/broken.mp4") }

        it "should not be valid" do
          movie.should_not be_valid
        end

        it "should have nil calculated_aspect_ratio" do
          movie.calculated_aspect_ratio.should be_nil
        end
      end

      context "given a weird aspect ratio file" do
        let(:movie) { Movie.new("#{fixture_path}/movies/weird_aspect.small.mpg") }

        it "should parse the DAR" do
          movie.dar.should == "704:405"
        end

        it "should have correct calculated_aspect_ratio" do
          movie.calculated_aspect_ratio.to_s[0..14].should == "1.7382716049382" # substringed to be 1.9 compatible
        end
      end

      describe 'Special cases: ' do
        let(:movie) do
          Open3.stub(:popen3).and_yield(nil,fake_output,nil)
          Movie.new(__FILE__)
        end

        context "given an impossible DAR" do
          let(:fixture_file) { 'file_with_weird_dar.txt' }

          it "should parse the DAR" do
            movie.dar.should == "0:1"
          end

          it "should calculate using width and height instead" do
            movie.calculated_aspect_ratio.to_s[0..14].should == "1.7777777777777" # substringed to be 1.9 compatible
          end
        end

        context 'given an impossible SAR' do
          let(:fixture_file) { 'file_with_weird_sar.txt' }

          it 'should parse the SAR' do
            movie.sar.should == '0:1'
          end

          it 'should using square SAR, 1.0 instead' do
            movie.calculated_pixel_aspect_ratio.to_s[0..14].should == '1' # substringed to be 1.9 compatible
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
            movie.audio_channels.should == 6
          end
        end

        context "given a file with no audio" do
          let(:fixture_file) { 'file_with_no_audio.txt' }

          it "should have nil audio channels" do
            movie.audio_channels.should == nil
          end
        end

        context "given a file with non supported audio" do
          let(:fixture_file) { 'file_with_non_supported_audio_stdout.txt' }
          let(:movie) do
            fake_stderr = StringIO.new(File.read("#{fixture_path}/outputs/file_with_non_supported_audio_stderr.txt"))
            Open3.stub(:popen3).and_yield(nil,fake_output,fake_stderr)
            Movie.new(__FILE__)
          end

          it "should be valid" do
            movie.should be_valid
          end
        end

        context "given a file with non supported audio and video" do
          let(:fixture_file) { 'file_with_non_supported_audio_and_video_stdout.txt' }
          let(:movie) do
            fake_stderr = StringIO.new(File.read("#{fixture_path}/outputs/file_with_non_supported_audio_and_video_stderr.txt"))
            Open3.stub(:popen3).and_yield(nil,fake_output,fake_stderr)
            Movie.new(__FILE__)
          end

          it "should not be valid" do
            movie.should_not be_valid
          end
        end

      end

      context "given a weird storage/pixel aspect ratio file" do
        let(:movie) { Movie.new("#{fixture_path}/movies/weird_aspect.small.mpg") }

        it "should parse the SAR" do
          movie.sar.should == "64:45"
        end

        it "should have correct calculated_pixel_aspect_ratio" do
          movie.calculated_pixel_aspect_ratio.to_s[0..14].should == "1.4222222222222" # substringed to be 1.9 compatible
        end
      end

      context "given an awesome movie file" do
        let(:movie) { Movie.new("#{fixture_path}/movies/awesome movie.mov") }

        it "should remember the movie path" do
          movie.path.should == "#{fixture_path}/movies/awesome movie.mov"
        end

        it "should parse duration to number of seconds" do
          expect(movie.duration).to be_within(0.01).of(7.56)
        end

        it "should parse the bitrate" do
          movie.bitrate.should == 481846
        end

        it "should return nil rotation when no rotation exists" do
          movie.rotation.should == nil
        end

        it "should parse the creation_time" do
          movie.creation_time.should == Time.parse("2010-02-05 16:05:04")
        end

        it "should parse video stream information" do
          movie.video_stream.should == "h264 (Main) (avc1 / 0x31637661), yuv420p, 640x480 [SAR 1:1 DAR 4:3]"
        end

        it "should know the video codec" do
          movie.video_codec.should =~ /h264/
        end

        it "should know the colorspace" do
          movie.colorspace.should == "yuv420p"
        end

        it "should know the resolution" do
          movie.resolution.should == "640x480"
        end

        it "should know the video bitrate" do
          movie.video_bitrate.should == 371185
        end

        it "should know the width and height" do
          movie.width.should == 640
          movie.height.should == 480
        end

        it "should know the framerate" do
          expect(movie.frame_rate).to be_within(0.01).of(16.75)
        end

        it "should parse audio stream information" do
          movie.audio_stream.should == "aac (mp4a / 0x6134706d), 44100 Hz, stereo, fltp, 75832 bit/s"
        end

        it "should know the audio codec" do
          movie.audio_codec.should =~ /aac/
        end

        it "should know the sample rate" do
          movie.audio_sample_rate.should == 44100
        end

        it "should know the number of audio channels" do
          movie.audio_channels.should == 2
        end

        it "should know the audio bitrate" do
          movie.audio_bitrate.should == 75832
        end

        it "should should be valid" do
          movie.should be_valid
        end

        it "should calculate the aspect ratio" do
          movie.calculated_aspect_ratio.to_s[0..14].should == "1.3333333333333" # substringed to be 1.9 compatible
        end

        it "should know the file size" do
          movie.size.should == 455546
        end

        it "should know the container" do
          movie.container.should == "mov,mp4,m4a,3gp,3g2,mj2"
        end
      end
    end

    context "given a rotated movie file" do
      let(:movie) { Movie.new("#{fixture_path}/movies/sideways movie.mov") }

      it "should parse the rotation" do
        movie.rotation.should == 90
      end
    end

    describe "transcode" do
      let(:movie) { Movie.new("#{fixture_path}/movies/awesome movie.mov")}

      it "should run the transcoder" do

        transcoder_double = double(Transcoder)
        Transcoder.should_receive(:new).
          with(movie, "#{tmp_path}/awesome.flv", {custom: "-vcodec libx264"}, preserve_aspect_ratio: :width).
          and_return(transcoder_double)
        transcoder_double.should_receive(:run)

        movie.transcode("#{tmp_path}/awesome.flv", {custom: "-vcodec libx264"}, preserve_aspect_ratio: :width)
      end
    end

    describe "screenshot" do
      let(:movie) { Movie.new("#{fixture_path}/movies/awesome movie.mov")}

      it "should run the transcoder with screenshot option" do

        transcoder_double = double(Transcoder)
        Transcoder.should_receive(:new).
          with(movie, "#{tmp_path}/awesome.jpg", {seek_time: 2, dimensions: "640x480", screenshot: true}, preserve_aspect_ratio: :width).
          and_return(transcoder_double)
        transcoder_double.should_receive(:run)

        movie.screenshot("#{tmp_path}/awesome.jpg", {seek_time: 2, dimensions: "640x480"}, preserve_aspect_ratio: :width)
      end
    end
  end
end
