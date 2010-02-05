#require File.dirname(__FILE__) + '/../spec_helper.rb'
require 'spec_helper.rb'

module FFMPEG
  describe Movie do
    describe "given a non existing file" do
      it "should throw ArgumentError" do
        lambda { Movie.new("i_dont_exist") }.should raise_error(Errno::ENOENT, /does not exist/)
      end
    end
    
    describe "given a non movie file" do
      before(:all) do
        @movie = Movie.new(__FILE__)
      end
      
      it "should not be valid" do
        @movie.should_not be_valid
      end
    end
    
    describe "given awesome.mov file" do
      before(:all) do
        @movie = Movie.new("#{fixture_path}/movies/awesome.mov")
      end

      it "should parse duration to number of seconds" do
        @movie.duration.should == 7.5
      end

      it "should parse video stream information" do
        @movie.video_stream.should == "h264, yuv420p, 640x480 [PAR 1:1 DAR 4:3], 371 kb/s, 16.75 fps, 15 tbr, 600 tbn, 1200 tbc"
      end

      it "should parse audio stream information" do
        @movie.audio_stream.should == "aac, 44100 Hz, stereo, s16, 75 kb/s"
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

      it "should know the width and height" do
        @movie.width.should == 640
        @movie.height.should == 480
      end

      it "should should be valid" do
        @movie.should be_valid
      end
    end
  end
end
