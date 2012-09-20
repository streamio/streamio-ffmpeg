require 'spec_helper.rb'

module FFMPEG
  describe Movie do
    describe "initializing" do
      context "given a non existing file" do
        it "should throw ArgumentError" do
          lambda { Movie.new("i_dont_exist") }.should raise_error(Errno::ENOENT, /does not exist/)
        end
      end
      
      context "given a file containing a single quotation mark in the filename" do
        before(:all) do
          @movie = Movie.new("#{fixture_path}/movies/awesome'movie.mov")
        end
        
        it "should run ffmpeg successfully" do
          @movie.duration.should == 7.56
          @movie.frame_rate.should == 16.75
        end
      end
      
      context "given a non movie file" do
        before(:all) do
          @movie = Movie.new(__FILE__)
        end

        it "should not be valid" do
          @movie.should_not be_valid
        end
        
        it "should have a duration of 0" do
          @movie.duration.should == 0
        end 
        
        it "should have nil height" do
          @movie.height.should be_nil
        end
        
        it "should have nil width" do
          @movie.width.should be_nil
        end
      
        it "should have nil frame_rate" do
          @movie.frame_rate.should be_nil
        end 
      end

      context "given an empty flv file (could not find codec parameters)" do
        before(:all) do
          @movie = Movie.new("#{fixture_path}/movies/empty.flv")
        end

        it "should not be valid" do
          @movie.should_not be_valid
        end
      end
      
      context "given a broken mp4 file" do
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

      context "given a weird aspect ratio file" do
        before(:all) do
          @movie = Movie.new("#{fixture_path}/movies/weird_aspect.small.mpg")
        end
        
        it "should parse the DAR" do
          @movie.dar.should == "704:405"
        end
        
        it "should have correct calculated_aspect_ratio" do
          @movie.calculated_aspect_ratio.to_s[0..14].should == "1.7382716049382" # substringed to be 1.9 compatible
        end
      end
      
      context "given an impossible DAR" do
        before(:all) do
          fake_output = StringIO.new(File.read("#{fixture_path}/outputs/file_with_weird_dar.txt"))
          Open3.stub!(:popen3).and_yield(nil,nil,fake_output)
          @movie = Movie.new(__FILE__)
        end
        
        it "should parse the DAR" do
          @movie.dar.should == "0:1"
        end

        it "should calulate using width and height instead" do
          @movie.calculated_aspect_ratio.to_s[0..14].should == "1.7777777777777" # substringed to be 1.9 compatible
        end
      end
      
      context "given a file with ISO-8859-1 characters in output" do
        it "should not crash" do
          fake_output = StringIO.new(File.read("#{fixture_path}/outputs/file_with_iso-8859-1.txt"))
          Open3.stub!(:popen3).and_yield(nil, nil, fake_output)
          expect { Movie.new(__FILE__) }.to_not raise_error
        end
      end
      
      context "given a file with 5.1 audio" do
        before(:all) do
          fake_output = StringIO.new(File.read("#{fixture_path}/outputs/file_with_surround_sound.txt"))
          Open3.stub!(:popen3).and_yield(nil, nil, fake_output)
          @movie = Movie.new(__FILE__)
        end
        
        it "should have 6 audio channels" do
          @movie.audio_channels.should == 6
        end
      end
      
      context "given a file with no audio" do
        before(:all) do
          fake_output = StringIO.new(File.read("#{fixture_path}/outputs/file_with_no_audio.txt"))
          Open3.stub!(:popen3).and_yield(nil, nil, fake_output)
          @movie = Movie.new(__FILE__)
        end
        
        it "should have nil audio channels" do
          @movie.audio_channels.should == nil
        end
      end
      
      context "given a file with non supported audio" do
        before(:all) do
          fake_output = StringIO.new(File.read("#{fixture_path}/outputs/file_with_non_supported_audio.txt"))
          Open3.stub!(:popen3).and_yield(nil, nil, fake_output)
          @movie = Movie.new(__FILE__)
        end
        
        it "should not be valid" do
          @movie.should_not be_valid
        end
      end
      
      context "given an awesome movie file" do
        before(:all) do
          @movie = Movie.new("#{fixture_path}/movies/awesome movie.mov")
        end
        
        it "should remember the movie path" do
          @movie.path.should == "#{fixture_path}/movies/awesome movie.mov"
        end

        it "should parse duration to number of seconds" do
          @movie.duration.should == 7.56
        end

        it "should parse the bitrate" do
          @movie.bitrate.should == 481
        end

        it "should return nil rotation when no rotation exists" do
          @movie.rotation.should == nil
        end

        it "should parse the creation_time" do
          @movie.creation_time.should == Time.parse("2010-02-05 16:05:04")
        end

        it "should parse video stream information" do
          @movie.video_stream.should == "h264 (Main) (avc1 / 0x31637661), yuv420p, 640x480 [SAR 1:1 DAR 4:3], 371 kb/s, 16.75 fps, 600 tbr, 600 tbn, 1200 tbc"
        end

        it "should know the video codec" do
          @movie.video_codec.should =~ /h264/
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
          @movie.audio_stream.should == "aac (mp4a / 0x6134706D), 44100 Hz, stereo, s16, 75 kb/s"
        end

        it "should know the audio codec" do
          @movie.audio_codec.should =~ /aac/
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
          @movie.calculated_aspect_ratio.to_s[0..14].should == "1.3333333333333" # substringed to be 1.9 compatible
        end
        
        it "should know the file size" do
          @movie.size.should == 455546
        end
      end
    end

    context "given a rotated movie file" do
      before(:all) do
        @movie = Movie.new("#{fixture_path}/movies/sideways movie.mov")
      end

      it "should parse the rotation" do
        @movie.rotation.should == 90
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
    
    describe "screenshot" do
      it "should run the transcoder with screenshot option" do
        movie = Movie.new("#{fixture_path}/movies/awesome movie.mov")
        
        mockery = mock(Transcoder)
        Transcoder.should_receive(:new).with(movie, "#{tmp_path}/awesome.jpg", {:seek_time => 2, :dimensions => "640x480", :screenshot => true}, :preserve_aspect_ratio => :width).and_return(mockery)
        mockery.should_receive(:run)
        
        movie.screenshot("#{tmp_path}/awesome.jpg", {:seek_time => 2, :dimensions => "640x480"}, :preserve_aspect_ratio => :width)
      end
    end
  end
end
