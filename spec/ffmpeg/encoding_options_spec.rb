require 'spec_helper.rb'

module FFMPEG
  describe EncodingOptions do
    describe "ffmpeg arguments conversion" do
      it "should convert video codec" do
        EncodingOptions.new(:video_codec => "libx264").to_s.should == "-vcodec libx264"
      end
      
      it "should convert cropping options" do
        EncodingOptions.new(:croptop => 20).to_s.should == "-croptop 20"
        EncodingOptions.new(:cropbottom => 20).to_s.should == "-cropbottom 20"
        EncodingOptions.new(:cropleft => 20).to_s.should == "-cropleft 20"
        EncodingOptions.new(:cropright => 20).to_s.should == "-cropright 20"
      end
      
      it "should know the width from the resolution or be nil" do
        EncodingOptions.new(:resolution => "320x240").width.should == 320
        EncodingOptions.new.width.should be_nil
      end
      
      it "should know the height from the resolution or be nil" do
        EncodingOptions.new(:resolution => "320x240").height.should == 240
        EncodingOptions.new.height.should be_nil
      end
      
      it "should convert frame rate" do
        EncodingOptions.new(:frame_rate => 29.9).to_s.should == "-r 29.9"
      end
      
      it "should convert the resolution" do
        EncodingOptions.new(:resolution => "640x480").to_s.should include("-s 640x480")
      end
      
      it "should add calculated aspect ratio" do
        EncodingOptions.new(:resolution => "640x480").to_s.should include("-aspect 1.3333333")
        EncodingOptions.new(:resolution => "640x360").to_s.should include("-aspect 1.77777777777778")
      end
      
      it "should use specified aspect ratio if given" do
        EncodingOptions.new(:resolution => "640x480", 
                            :aspect => 1.77777777777778).to_s.should == "-s 640x480 -aspect 1.77777777777778"
      end
      
      it "should convert video bitrate" do
        EncodingOptions.new(:video_bitrate => "600k").to_s.should == "-b 600k"
      end
      
      it "should use k unit for video bitrate" do
        EncodingOptions.new(:video_bitrate => 600).to_s.should == "-b 600k"
      end
      
      it "should convert audio codec" do
        EncodingOptions.new(:audio_codec => "aac").to_s.should == "-acodec aac"
      end
      
      it "should convert audio bitrate" do
        EncodingOptions.new(:audio_bitrate => "128k").to_s.should == "-ab 128k"
      end
      
      it "should use k unit for audio bitrate" do
        EncodingOptions.new(:audio_bitrate => 128).to_s.should == "-ab 128k"
      end
      
      it "should convert audio sample rate" do
        EncodingOptions.new(:audio_sample_rate => 44100).to_s.should == "-ar 44100"
      end
      
      it "should convert audio channels" do
        EncodingOptions.new(:audio_channels => 2).to_s.should == "-ac 2"
      end
      
      it "should convert a lot of them simultaneously" do
        converted = EncodingOptions.new(:video_codec => "libx264", :audio_codec => "aac", :video_bitrate => "1000k").to_s
        converted.should match(/-acodec aac/)
      end
    end
  end
end