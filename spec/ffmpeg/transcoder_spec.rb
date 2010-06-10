require 'spec_helper.rb'

module FFMPEG
  describe Transcoder do
    describe "initialization" do
      before(:each) do
        @movie = Movie.new("#{fixture_path}/movies/awesome movie.mov")
        @output_path = "#{tmp_path}/awesome.flv"
      end
      
      it "should accept EncodingOptions as options" do
        lambda { Transcoder.new(@movie, @output_path, EncodingOptions.new) }.should_not raise_error(ArgumentError)
      end
      
      it "should accept Hash as options" do
        lambda { Transcoder.new(@movie, @output_path, :video_codec => "libx264") }.should_not raise_error(ArgumentError)
      end
      
      it "should accept String as options" do
        lambda { Transcoder.new(@movie, @output_path, "-vcodec libx264") }.should_not raise_error(ArgumentError)
      end
      
      it "should not accept anything else as options" do
        lambda { Transcoder.new(@movie, @output_path, ["array?"]) }.should raise_error(ArgumentError, /Unknown options format/)
      end
    end
    
    describe "transcoding" do
      before(:each) do
        FFMPEG.logger.should_receive(:info).at_least(:once)
      end
      
      it "should transcode the movie with progress given an awesome movie" do
        FileUtils.rm_f "#{tmp_path}/awesome.flv"
        
        movie = Movie.new("#{fixture_path}/movies/awesome movie.mov")
        
        transcoder = Transcoder.new(movie, "#{tmp_path}/awesome.flv")
        stored_progress = 0
        transcoder.run { |progress| stored_progress = progress }
        transcoder.encoded.should be_valid
        stored_progress.should == 1.0
        File.exists?("#{tmp_path}/awesome.flv").should be_true
      end
      
      it "should transcode the movie with EncodingOptions" do
        FileUtils.rm_f "#{tmp_path}/optionalized.mp4"
        
        movie = Movie.new("#{fixture_path}/movies/awesome movie.mov")
        options = {:video_codec => "libx264", :frame_rate => 10, :resolution => "320x240", :video_bitrate => 300,
                   :audio_codec => "libfaac", :audio_bitrate => 32, :audio_sample_rate => 22050, :audio_channels => 1,
                   :custom => "-flags +loop -cmp +chroma -partitions +parti4x4+partp8x8 -flags2 +mixed_refs -me_method umh -subq 6 -refs 6 -rc_eq 'blurCplx^(1-qComp)' -coder 0 -me_range 16 -g 250 -keyint_min 25 -sc_threshold 40 -i_qfactor 0.71 -qcomp 0.6 -qmin 10 -qmax 51 -qdiff 4 -level 21"}
        
        encoded = Transcoder.new(movie, "#{tmp_path}/optionalized.mp4", options).run
        encoded.video_codec.should == "h264"
        encoded.resolution.should == "320x240"
        encoded.frame_rate.should == 10.0
        encoded.audio_codec.should == "aac"
        encoded.audio_sample_rate.should == 22050
        encoded.audio_channels.should == 1
      end
      
      describe "aspect ratio preservation" do
        before(:each) do
          @movie = Movie.new("#{fixture_path}/movies/awesome_widescreen.mov")
          @options = {:resolution => "320x240"}
        end
        
        it "should work on width" do
          special_options = {:preserve_aspect_ratio => :width}

          encoded = Transcoder.new(@movie, "#{tmp_path}/preserved_aspect.mp4", @options, special_options).run
          encoded.resolution.should == "320x180"
        end

        it "should work on height" do
          special_options = {:preserve_aspect_ratio => :height}
        
          encoded = Transcoder.new(@movie, "#{tmp_path}/preserved_aspect.mp4", @options, special_options).run
          encoded.resolution.should == "426x240"
        end
        
        it "should not be used if original resolution is undeterminable" do
          @movie.should_receive(:calculated_aspect_ratio).and_return(nil)
          special_options = {:preserve_aspect_ratio => :height}
          
          encoded = Transcoder.new(@movie, "#{tmp_path}/preserved_aspect.mp4", @options, special_options).run
          encoded.resolution.should == "320x240"
        end
        
        it "should round to resolutions divisible by 2" do
          @movie.should_receive(:calculated_aspect_ratio).at_least(:once).and_return(1.234)
          special_options = {:preserve_aspect_ratio => :width}
          
          encoded = Transcoder.new(@movie, "#{tmp_path}/preserved_aspect.mp4", @options, special_options).run
          encoded.resolution.should == "320x260" # 320 / 1.234 should at first be rounded to 259
        end
      end

      it "should transcode the movie with String options" do
        FileUtils.rm_f "#{tmp_path}/string_optionalized.flv"
        
        movie = Movie.new("#{fixture_path}/movies/awesome movie.mov")
        
        encoded = Transcoder.new(movie, "#{tmp_path}/string_optionalized.flv", "-s 300x200 -ac 2").run
        encoded.resolution.should == "300x200"
        encoded.audio_channels.should == 2
      end
      
      it "should fail when given an invalid movie" do
        FFMPEG.logger.should_receive(:error)
        movie = Movie.new(__FILE__)
        transcoder = Transcoder.new(movie, "#{tmp_path}/fail.flv")
        lambda { transcoder.run }.should raise_error(RuntimeError, /no output file created/)
      end
      
      it "should fail if duration differs from original" do
        movie = Movie.new("#{fixture_path}/sounds/napoleon.mp3")
        movie.stub!(:duration).and_return(200)
        movie.stub!(:uncertain_duration?).and_return(false)
        transcoder = Transcoder.new(movie, "#{tmp_path}/duration_fail.flv")
        lambda { transcoder.run }.should raise_error(RuntimeError, /encoded file duration differed from original/)
      end
      
      it "should skip duration check if originals duration is uncertain" do
        movie = Movie.new("#{fixture_path}/sounds/napoleon.mp3")
        movie.stub!(:duration).and_return(200)
        movie.stub!(:uncertain_duration?).and_return(true)
        transcoder = Transcoder.new(movie, "#{tmp_path}/duration_fail.flv")
        lambda { transcoder.run }.should_not raise_error(RuntimeError)
      end
      
      it "should be able to transcode to images" do
        movie = Movie.new("#{fixture_path}/movies/awesome movie.mov")
        
        encoded = Transcoder.new(movie, "#{tmp_path}/image.png", :custom => "-ss 00:00:03 -vframes 1 -f image2").run
        encoded.resolution.should == "640x480"
        
        encoded = Transcoder.new(movie, "#{tmp_path}/image.jpg", :custom => "-ss 00:00:03 -vframes 1 -f image2").run
        encoded.resolution.should == "640x480"
      end
    end
  end
end