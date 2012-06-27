if RUBY_VERSION =~ /1\.8/
	# Useful when `timeout.rb`, which, on M.R.I 1.8, relies on green threads, does not work consistently.
	begin
		require 'system_timer'
		FFMPEG::Timer = SystemTimer
	rescue LoadError
		require 'timeout'
		FFMPEG::Timer = Timeout
	end
else
	require 'timeout'
	FFMPEG::Timer = Timeout
end

require 'win32/process' if RUBY_PLATFORM =~ /(win|w)(32|64)$/

#
# Monkey Patch timeout support into the IO class
#
class IO
  def each_with_timeout(pid, seconds, sep_string=$/)
  	sleeping_queue = Queue.new
  	thread = nil

  	timer_set = lambda do
  	  thread = new_thread(pid) { FFMPEG::Timer.timeout(seconds) { sleeping_queue.pop } }
  	end

  	timer_cancel = lambda do
  		thread.kill if thread rescue nil
  	end

  	timer_set.call
  	each(sep_string) do |buffer|
  		timer_cancel.call
  		yield buffer
  		timer_set.call
  	end
  ensure
  	timer_cancel.call
  end

  private
  def new_thread(pid, &block)
  	current_thread = Thread.current
  	Thread.new do
  		begin
  			block.call
  		rescue Exception => e
  			current_thread.raise e
  			if RUBY_PLATFORM =~ /(win|w)(32|64)$/
  				Process.kill(1, pid)
  			else
  				Process.kill('SIGKILL', pid)
  			end
  		end
  	end
  end
end
