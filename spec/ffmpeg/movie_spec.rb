require 'spec_helper.rb'

module FFMPEG
  
  describe Movie do
    describe "given a non existing file" do
      it "should throw ArgumentError" do
        lambda { Movie.new("i_dont_exist") }.should raise_error(Errno::ENOENT, /does not exist/)
      end
    end
    
    describe "parsing" do
      describe "given a non movie file" do
        before(:all) do
          @movie = Movie.new(__FILE__)
        end

        it "should not be valid" do
          @movie.should_not be_valid
        end
      end
      
      describe "given a mp3 file" do
        before(:all) do
          @movie = Movie.new("#{fixture_path}/sounds/napoleon.mp3")
        end
        
        it "should have uncertain duration" do
          @movie.should be_uncertain_duration
        end
      end
      
      describe "a broken mp4 file" do
        before(:all) do
          @movie = Movie.new("#{fixture_path}/movies/broken.mp4")
        end
        
        it "should not be valid" do
          @movie.should_not be_valid
        end

        it "should have nil calculated_aspect_ratio" do
          @movie.calculated_aspect_ratio.should be_nil
        end
      end

      describe "given a weird aspect ratio file" do
        before(:all) do
          @movie = Movie.new("#{fixture_path}/movies/weird_aspect.small.mpg")
        end
        
        it "should parse the DAR" do
          @movie.dar.should == "704:405"
        end
        
        it "should have correct calculated_aspect_ratio" do
          @movie.calculated_aspect_ratio.to_s[0..15].should == "1.73827160493827" # substringed to be 1.9 compatible
        end
      end

      describe "given a file with start-time" do
        before(:each) do
          fake_output = StringIO.new(File.read("#{fixture_path}/outputs/file_with_start_value.txt"))
          Open3.stub!(:popen3).and_return([nil,nil,fake_output])
          @movie = Movie.new(__FILE__)
        end
        
        it "should have an uncertain duration" do
          @movie.should be_uncertain_duration
        end
      end
      
      describe "given a file with ISO-8859-1 characters in output" do
        it "should not crash" do
          fake_output = StringIO.new(File.read("#{fixture_path}/outputs/file_with_iso-8859-1.txt"))
          Open3.stub!(:popen3).and_return([nil,nil,fake_output])
          expect { Movie.new(__FILE__) }.to_not raise_error
        end
      end
      
      describe "given an awesome movie file" do
        before(:all) do
          @movie = Movie.new("#{fixture_path}/movies/awesome movie.mov")
        end

        it "should not have uncertain duration" do
          @movie.should_not be_uncertain_duration
        end
        
        it "should remember the movie path" do
          @movie.path.should == "#{fixture_path}/movies/awesome movie.mov"
        end

        it "should parse duration to number of seconds" do
          @movie.duration.should == 7.5
        end

        it "should parse the bitrate" do
          @movie.bitrate.should == 481
        end

        it "should parse video stream information" do
          @movie.video_stream.should == "h264, yuv420p, 640x480 [PAR 1:1 DAR 4:3], 371 kb/s, 16.75 fps, 15 tbr, 600 tbn, 1200 tbc"
        end

        it "should know the video codec" do
          @movie.video_codec.should == "h264"
        end

        it "should know the colorspace" do
          @movie.colorspace.should == "yuv420p"
        end

        it "should know the resolution" do
          @movie.resolution.should == "640x480"
        end

        it "should know the video bitrate" do
          @movie.video_bitrate.should == 371
        end

        it "should know the width and height" do
          @movie.width.should == 640
          @movie.height.should == 480
        end

        it "should know the framerate" do
          @movie.frame_rate.should == 16.75
        end

        it "should parse audio stream information" do
          @movie.audio_stream.should == "aac, 44100 Hz, stereo, s16, 75 kb/s"
        end

        it "should know the audio codec" do
          @movie.audio_codec.should == "aac"
        end

        it "should know the sample rate" do
          @movie.audio_sample_rate.should == 44100
        end

        it "should know the number of audio channels" do
          @movie.audio_channels.should == 2
        end

        it "should know the audio bitrate" do
          @movie.audio_bitrate.should == 75
        end

        it "should should be valid" do
          @movie.should be_valid
        end
        
        it "should calculate the aspect ratio" do
          @movie.calculated_aspect_ratio.to_s[0..15].should == "1.33333333333333" # substringed to be 1.9 compatible
        end
        
        it "should know the file size" do
          @movie.size.should == 455546
        end
      end
    end
    
    describe "transcode" do
      it "should run the transcoder" do
        movie = Movie.new("#{fixture_path}/movies/awesome movie.mov")

        mockery = mock(Transcoder)
        Transcoder.should_receive(:new).with(movie, "#{tmp_path}/awesome.flv", {:custom => "-vcodec libx264"}, :preserve_aspect_ratio => :width).and_return(mockery)
        mockery.should_receive(:run)

        movie.transcode("#{tmp_path}/awesome.flv", {:custom => "-vcodec libx264"}, :preserve_aspect_ratio => :width)
      end
    end
  end
  
end
