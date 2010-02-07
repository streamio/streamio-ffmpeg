require 'spec_helper.rb'

module FFMPEG
  describe Transcoder do
    describe "initializing" do
      it "should require an output_file option" do
        lambda { Transcoder.new(nil, {}) }.should raise_error(ArgumentError, /output_file/)
      end
    end
    
    describe "transcoding" do
      it "should transcode the movie" do
        FileUtils.rm_f "#{tmp_path}/awesome.flv"
        movie = Movie.new("#{fixture_path}/movies/awesome.mov")
        transcoder = Transcoder.new(movie, :output_file => "tmp/awesome.flv")
        transcoder.run
        transcoder.encoded.should be_valid
        File.exists?("#{tmp_path}/awesome.flv").should be_true
      end
    end
  end
end