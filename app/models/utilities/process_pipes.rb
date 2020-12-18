module Utilities
  #
  # Fork a process to run an external command that either:
  # sends results to a pipe, receives results from a pipe,
  # or receives results from one pipe then sends results to another pipe
  #
  # Setup with:
  #     pipe_pair_1 = IO.pipe
  #     pipe_pair_result = IO.pipe
  #
  # Send to pipe:
  #     pipe_in_out nil, pipe_pair_1, ['echo', 'AB 123 456 789']
  #
  # Receive result from pipe chain:
  #     pipe_in_out pipe_pair_1, pipe_pair_result ['wc']
  #     puts pipe_result(pipe_pair_result)
  #
  # Send and receive together would do the equivalent of `echo AB 123 456 789' | wc`
  #
  # To chain 3 commands:
  #
  #     pipe_pair1 = IO.pipe
  #     pipe_pair2 = IO.pipe
  #     pipe_pair_result = IO.pipe
  #     pipe_in_out nil, pipe_pair1,  ['echo', 'ABC12345 234234 24523']
  #     pipe_in_out pipe_pair1, pipe_pair2, ['wc']
  #     pipe_in_out pipe_pair2, pipe_pair_result, ['grep', '1']
  #     puts pipe_result(pipe_pair_result)
  #
  # This does the equivalent of `echo 'ABC12345 234234 24523' | wc | grep '1'`
  class ProcessPipes
    def initialize(pipe_chain)
      @threads = []
      @pipe_pairs = []
      @pipe_chain = pipe_chain
      @pipe_chain.each do
        @pipe_pairs << IO.pipe
      end
    end

    def run
      pipe_pos = 0
      p_in = nil

      # First time through the pipe will be set up with no inbound pipe. Subsequent commands
      # in the chain will have both an inbound and outbound pipe
      @pipe_chain.each do |pipe_cmd|
        p_out = @pipe_pairs[pipe_pos]
        @threads << Utilities::ProcessPipes.pipe_in_out(p_in, p_out, pipe_cmd)
        p_in = @pipe_pairs[pipe_pos]
        pipe_pos += 1
      end

      @threads.each do |t|
        raise FphsException, "Failed pipe thread #{t.value}" if t.value == false
      end

      self.class.pipe_result @pipe_pairs.last
    rescue StandardError => e
      cleanup!
      raise
    end

    def cleanup!
      @pipe_pairs.each do |pp|
        pp&.each do |p|
          p&.close
        end
      end

      @threads.each do |t|
        t&.exit if t.status
      end

      @threads = []
      @pipe_pairs = []
    end

    # Run a command receiving from a pipe and / or sending to another pipe
    # @param [Array | nil] pipe_pair_in - array representing a pipe pair returned from IO.pipe
    # @param [Array | nil] pipe_pair_out - array representing a pipe pair returned from IO.pipe
    # @param [Array] cmd - valid external command to be called with popen
    # @return [Thread] new thread
    def self.pipe_in_out(pipe_pair_in, pipe_pair_out, cmd)
      Thread.new do
        perm = 'r'
        perm = 'r+' if pipe_pair_in

        # puts pipe_pair_in, pipe_pair_out, cmd
        sleep 4
        res = IO.popen(cmd, perm) do |stdinout|
          fork do
            if pipe_pair_in
              pipe_to1, pipe_from1 = pipe_pair_in
              pipe_from1.close
              # puts "Waiting for #{cmd} with #{pipe_to1} in #{Process.pid}"
              piped_in = nil
              piped_in = pipe_to1.read until piped_in
              # puts "Got piped input: #{piped_in}"
              pipe_to1.close

              stdinout.write piped_in
              stdinout.close_write
            end

            res = stdinout.read
            # puts "result length #{cmd}: #{res&.length}"

            if pipe_pair_out
              pipe_to2, pipe_from2 = pipe_pair_out
              pipe_to2.close

              pipe_from2.write res
              pipe_from2.close
            end
          end
        end

        if $?.success?
          true
        else
          raise FphsException, "Failed popen (#{cmd}): #{$?} - #{res}"
        end

      rescue StandardError => e

        Rails.logger.warn "Failure in pipe_in_out (#{cmd}): #{e}"
        pipe_to1&.close
        pipe_from1&.close
        pipe_to2&.close
        pipe_from2&.close

        false
      end
    end

    # Get the final result from a series of pipes.
    # @param [Array] pipe_pair_result - array representing a pipe pair returned from IO.pipe
    # @return [String] result from the pipe
    def self.pipe_result(pipe_pair_result)
      pipe_pair_result[1].close
      output = pipe_pair_result[0].read
      pipe_pair_result[0].close
      output
    end
  end
end
