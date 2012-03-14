require 'open3'
require 'shellwords'

module FFMPEG
  class Thumbnailer
    def initialize(movie,output_file,options = {})
      @options = ThumnbailingOptions.new(options)
      @movie = movie
      @output_file = output_file
    end
    
    def run
      command = "#{FFMPEG.ffmpeg_binary} #{@options.preceding} -y -i #{Shellwords.escape(@movie.path)} #{@options.following} #{@output_file}"
      FFMPEG.logger.info("Running thumbnailing...\n#{command}\n")
      output = ""
      last_output = nil
      Open3.popen3(command) do |stdin, stdout, stderr|
        stderr.each("\n") do |line|
          puts line
        end
      end
      
    end
  end
end