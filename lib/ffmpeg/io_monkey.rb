

if RUBY_VERSION =~ /1\.8/
	#
	# This is useful when `timeout.rb`, which, on M.R.I 1.8, relies on green threads, does not work consistently.
	#
	begin
		require 'system_timer'
		MyTimer = SystemTimer
	rescue LoadError
		require 'timeout'
		MyTimer = Timeout
	end
else
	require 'timeout'
	MyTimer = Timeout
end


#
# Monkey Patch timeout support into the IO class
#
class IO
	def each_with_timeout(timeout, sep_string=$/)
		q = Queue.new
		th = nil

		timer_set = lambda do |timeout|
			th = new_thread{ to(timeout){ q.pop } }
		end

		timer_cancel = lambda do |timeout|
			th.kill if th rescue nil
		end

		timer_set[timeout]
		begin
			self.each(sep_string) do |buf|
				timer_cancel[timeout]
				yield buf
				timer_set[timeout]
			end
		ensure
			timer_cancel[timeout]
		end
	end
	
	
	private
	
	
	def new_thread(*a, &b)
		cur = Thread.current
		Thread.new(*a) do |*a|
			begin
				b[*a]
			rescue Exception => e
				cur.raise e
			end
		end
	end
	
	def to timeout = nil
		MyTimer.timeout(timeout){ yield }
	end
end
