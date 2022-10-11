# frozen_string_literal: true

module Utilities
  #
  # Use popen to create a subprocess connected to Ruby through a pipe:
  # optionally sends results to the pipe, receives results from the pipe
  #
  # Send to pipe (no initial piped in data):
  #     res = ProcessPipes.pipe_in_out nil, ['echo', 'AB 123 456 789']
  #
  # Receive result from pipe chain:
  #     res = ProcessPipes.pipe_in_out res, ['wc']
  #
  # Send and receive together do the equivalent of `echo AB 123 456 789' | wc`
  #
  # To chain 3 commands:
  #
  #     res = ProcessPipes.pipe_in_out nil, ['echo', 'ABC12345 234234 24523']
  #     ProcessPipes.pipe_in_out res, ['wc']
  #     ProcessPipes.pipe_in_out res, ['grep', '1']
  #
  # This does the equivalent of `echo 'ABC12345 234234 24523' | wc | grep '1'`
  #
  # To simplify, allow an instance of the class to handle the chaining
  #
  #    chain = ProcessPipes.new [
  #      ['echo', 'ABC12345 234234 24523'],
  #      ['wc'],
  #      ['grep', '1']
  #    ]
  #    chain.run
  #
  class ProcessPipes
    MaxRunTime = 10

    def initialize(pipe_chain)
      @pipe_chain = pipe_chain
    end

    def run
      res = nil

      # First time through the pipe will be set up with no inbound pipe. Subsequent commands
      # in the chain will pass in the previous result
      @pipe_chain.each do |pipe_cmd|
        res = Utilities::ProcessPipes.pipe_in_out(res, pipe_cmd)
      end

      res
    end

    # Run a command optionally receiving from a pipe.
    # A timeout is set to ensure a failed or blocked command does not block indefinitely.
    # Write and read to / from the the process run within their own threads, to ensure that
    # writing to a full pipe, which is waiting on the process to send data back to
    # Ruby does not block forever (running synchronously the write can't complete because
    # some data must be read out but the read won't start until the write is complete).
    # @param [Array | nil] pipe_in - optional data to pipe in
    # @param [Array] cmd - valid external command to be called with popen
    # @return [Thread] new thread
    def self.pipe_in_out(pipe_in, cmd)
      perm = 'r'
      perm = 'r+' if pipe_in

      res = nil
      IO.popen(cmd, perm) do |stdinout|
        Timeout.timeout(MaxRunTime) do
          t1 = Thread.new do
            if pipe_in
              stdinout.write pipe_in
              stdinout.close_write
            end
          end

          t2 = Thread.new do
            res = stdinout.read
          end

          t1.join
          t2.join

          # puts "result length #{cmd}: #{res&.length}"
        end
      rescue Timeout::Error
        ::Process.kill 9, stdinout.pid
        Rails.logger.warn "Process popen timed out: #{cmd}"
      end

      raise FphsException, "Failed popen (#{cmd}): #{$?} - #{res}" unless $?.success?

      res
    rescue StandardError => e
      Rails.logger.warn "Failure in pipe_in_out (#{cmd}): #{e}"
      raise
    end
  end
end
