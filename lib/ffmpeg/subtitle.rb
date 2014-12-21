module FFMPEG
  class Subtitle
    attr_reader :language, :raw
    
    def initialize(language, raw)
      @language = language
      @raw      = raw
    end
    
  end
end
