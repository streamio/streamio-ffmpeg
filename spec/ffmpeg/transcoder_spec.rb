require 'spec_helper.rb'

module FFMPEG
  describe Transcoder do
    let(:movie) { Movie.new("#{fixture_path}/movies/awesome movie.mov") }
      
    describe "initialization" do
      let(:output_path) { "#{tmp_path}/awesome.flv" }
      
      it "should accept EncodingOptions as options" do
        lambda { Transcoder.new(movie, output_path, EncodingOptions.new) }.should_not raise_error(ArgumentError)
      end
      
      it "should accept Hash as options" do
        lambda { Transcoder.new(movie, output_path, :video_codec => "libx264") }.should_not raise_error(ArgumentError)
      end
      
      it "should accept String as options" do
        lambda { Transcoder.new(movie, output_path, "-vcodec libx264") }.should_not raise_error(ArgumentError)
      end
      
      it "should not accept anything else as options" do
        lambda { Transcoder.new(movie, output_path, ["array?"]) }.should raise_error(ArgumentError, /Unknown options format/)
      end
    end
    
    describe "transcoding" do
      before do
        FFMPEG.logger.should_receive(:info).at_least(:once)
      end
      
      it "should fail when IO timeout is exceeded" do
        FFMPEG.logger.should_receive(:error)
        movie = Movie.new("#{fixture_path}/movies/awesome_widescreen.mov")
        Transcoder.timeout = 1
        transcoder = Transcoder.new(movie, "#{tmp_path}/timeout.mp4")
        lambda { transcoder.run }.should raise_error(RuntimeError, /Process hung/)
      end
        
      Transcoder.timeout = 200
        
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
        
        options = {:video_codec => "libx264", :frame_rate => 10, :resolution => "320x240", :video_bitrate => 300,
                   :audio_codec => "libfaac", :audio_bitrate => 32, :audio_sample_rate => 22050, :audio_channels => 1,
                   :custom => "-flags +loop -cmp +chroma -partitions +parti4x4+partp8x8 -flags2 +mixed_refs -me_method umh -subq 6 -refs 6 -rc_eq 'blurCplx^(1-qComp)' -coder 0 -me_range 16 -g 250 -keyint_min 25 -sc_threshold 40 -i_qfactor 0.71 -qcomp 0.6 -qmin 10 -qmax 51 -qdiff 4 -level 21"}
        
        encoded = Transcoder.new(movie, "#{tmp_path}/optionalized.mp4", options).run
        encoded.video_codec.should =~ /h264/
        encoded.resolution.should == "320x240"
        encoded.frame_rate.should == 10.0
        encoded.audio_codec.should =~ /aac/
        encoded.audio_sample_rate.should == 22050
        encoded.audio_channels.should == 1
      end
      
      context "with aspect ratio preservation" do
        before do
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
        
        encoded = Transcoder.new(movie, "#{tmp_path}/string_optionalized.flv", "-s 300x200 -ac 2").run
        encoded.resolution.should == "300x200"
        encoded.audio_channels.should == 2
      end
      
      it "should transcode the movie which name include single quotation mark" do
        FileUtils.rm_f "#{tmp_path}/output.flv"
        
        movie = Movie.new("#{fixture_path}/movies/awesome'movie.mov")
        
        lambda { Transcoder.new(movie, "#{tmp_path}/output.flv").run }.should_not raise_error
      end
      
      it "should transcode when output filename includes single quotation mark" do
        FileUtils.rm_f "#{tmp_path}/output with 'quote.flv"
        
        lambda { Transcoder.new(movie, "#{tmp_path}/output with 'quote.flv").run }.should_not raise_error
      end
      
      pending "should not crash on ISO-8859-1 characters (dont know how to spec this)"
      
      it "should fail when given an invalid movie" do
        FFMPEG.logger.should_receive(:error)
        movie = Movie.new(__FILE__)
        transcoder = Transcoder.new(movie, "#{tmp_path}/fail.flv")
        lambda { transcoder.run }.should raise_error(FFMPEG::Error, /no output file created/)
      end
      
      it "should encode to the specified duration if given" do
        encoded = Transcoder.new(movie, "#{tmp_path}/durationalized.mp4", :duration => 2).run
        
        encoded.duration.should >= 1.8
        encoded.duration.should <= 2.2
      end
      
      context "with screenshot option" do
        it "should transcode to original movies resolution by default" do
          encoded = Transcoder.new(movie, "#{tmp_path}/image.jpg", :screenshot => true).run
          encoded.resolution.should == "640x480"
        end
        
        it "should transcode absolute resolution if specified" do
          encoded = Transcoder.new(movie, "#{tmp_path}/image.bmp", :screenshot => true, :seek_time => 3, :resolution => '400x200').run
          encoded.resolution.should == "400x200"
        end
        
        it "should be able to preserve aspect ratio" do
          encoded = Transcoder.new(movie, "#{tmp_path}/image.png", {:screenshot => true, :seek_time => 4, :resolution => '320x500'}, :preserve_aspect_ratio => :width).run
          encoded.resolution.should == "320x240"
        end
      end
    end
  end
end
