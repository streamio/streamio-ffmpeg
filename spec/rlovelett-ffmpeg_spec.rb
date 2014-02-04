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

  describe '.ffmpeg_binary' do

    after(:each) do
      FFMPEG.ffmpeg_binary = nil
    end

    it 'should default to finding from path' do
      allow(FFMPEG).to receive(:which) { '/usr/local/bin/ffmpeg' }
      expect(FFMPEG.ffmpeg_binary).to eq FFMPEG.which('ffprobe')
    end

    it 'should be assignable' do
      allow(File).to receive(:executable?).with('/new/path/to/ffmpeg') { true }
      FFMPEG.ffmpeg_binary = '/new/path/to/ffmpeg'
      expect(FFMPEG.ffmpeg_binary).to eq '/new/path/to/ffmpeg'
    end

    it 'should raise exception if it cannot find assigned executable' do
      expect { FFMPEG.ffmpeg_binary = '/new/path/to/ffmpeg' }.to raise_error(Errno::ENOENT)
    end

    it 'should raise exception if it cannot find executable on path' do
      allow(File).to receive(:executable?) { false }
      expect { FFMPEG.ffmpeg_binary }.to raise_error(Errno::ENOENT)
    end

  end

  describe '.ffprobe_binary' do

    after(:each) do
      FFMPEG.ffprobe_binary = nil
    end

    it 'should default to finding from path' do
      allow(FFMPEG).to receive(:which) { '/usr/local/bin/ffprobe' }
      expect(FFMPEG.ffprobe_binary).to eq FFMPEG.which('ffprobe')
    end

    it 'should be assignable' do
      allow(File).to receive(:executable?).with('/new/path/to/ffprobe') { true }
      FFMPEG.ffprobe_binary = '/new/path/to/ffprobe'
      expect(FFMPEG.ffprobe_binary).to eq '/new/path/to/ffprobe'
    end

    it 'should raise exception if it cannot find assigned executable' do
      expect { FFMPEG.ffprobe_binary = '/new/path/to/ffprobe' }.to raise_error(Errno::ENOENT)
    end

    it 'should raise exception if it cannot find executable on path' do
      allow(File).to receive(:executable?) { false }
      expect { FFMPEG.ffprobe_binary }.to raise_error(Errno::ENOENT)
    end

  end
end