require 'spec_helper.rb'

describe FFMPEG do
  
  describe 'parse options' do
    it 'empty string' do
      options = FFMPEG.parse_options("")
      expect(options).to eq []
    end

    it 'nested brackets' do
      options = FFMPEG.parse_options("h264 (Main) (avc1 / 0x31637661), yuv420p(tv, bt709), 960x540, 6520 kb/s, 23.98 fps, 23.98 tbr, 24k tbn, 48k tbc (default)")
      expect(options).to eq ["h264 (Main) (avc1 / 0x31637661)", "yuv420p(tv, bt709)", "960x540", "6520 kb/s", "23.98 fps", "23.98 tbr", "24k tbn", "48k tbc (default)"]
    end
  end

end
