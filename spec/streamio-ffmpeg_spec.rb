require 'spec_helper'

describe FFMPEG do
  describe "logger" do
    after(:each) do
      FFMPEG.logger = Logger.new(nil)
    end
    
    it "should be a Logger" do
      FFMPEG.logger.should be_instance_of(Logger)
    end
    
    it "should be at info level" do
      FFMPEG.logger = nil # Reset the logger so that we get the default
      FFMPEG.logger.level.should == Logger::INFO
    end
    
    it "should be assignable" do
      new_logger = Logger.new(STDOUT)
      FFMPEG.logger = new_logger
      FFMPEG.logger.should == new_logger
    end
  end
end