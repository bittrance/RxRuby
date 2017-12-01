module Rx
  # ThreadedEnumerator can be used across threads unlike Ruby's default Enumerator
  # that will throw FiberError if the enumerator is used from more than one
  # thread. You should use this class instead of vanilla Enumerator with oeprators
  # such as Rx::Observable.concat or Rx::Observable#rescue_error if they observe
  # on multiple async sources. Note that this does not mean that ThreadedEnumerator
  # is thread-safe in the stricter sense of the word: avoid calling #next from
  # multiple threads concurrently.
  class ThreadedEnumerator
    ERROR = Object.new
    DONE = Object.new

    if RUBY_ENGINE == 'jruby'
      def self.new(*args, &block)
        Enumerator.new(*args, &block)
      end
    end

    # ThreadedEnumerator helper class
    class Yielder
      def initialize(queue, condition)
        @queue = queue
        @condition = condition
        @gate = Mutex.new
      end

      def <<(e)
        @gate.synchronize do
          @queue << e
          @condition.wait @gate while @queue.size > 0
        end
      end
    end

    # The enumerator can be created with either an enumerable or a block that
    # receives a yielder object, but not both. Note that the block or enumerable
    # will be iterated immediately once making it possible to prepare the iterator
    # e.g. when reading from a file or a socket.
    def initialize(source_or_size_hint = nil, &block)
      raise TypeError, 'Size hinting not supported' if source_or_size_hint && block_given?
      @condition = ConditionVariable.new
      @queue = Queue.new
      @done = false
      setup_yielder(source_or_size_hint, &block)
    end

    # Receive the next item from the enumerator or any exception thrown from the
    # enumerator.
    def next
      raise StopIteration if @done
      @condition.signal
      payload, type = @queue.pop
      case type
      when DONE
        @done = true
        raise StopIteration
      when ERROR
        @done = true
        raise payload
      end
      payload
    end

    private

    def setup_yielder(source, &block)
      yielder = Yielder.new(@queue, @condition)
      Thread.new do
        begin
          if source
            source.each { |e| yielder << e }
          else
            block.call yielder
          end
        rescue => e
          yielder << [e, ERROR]
        end
        yielder << [nil, DONE]
      end
    end
  end
end
