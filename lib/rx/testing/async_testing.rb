module Rx
  module AsyncTesting
    def async_observable(*messages)
      Rx::Observable.create do |observer|
        Thread.new do
          sleep 0.001
          messages.each do |m|
            m.value.accept observer
          end
        end
      end
    end

    def await_array_length(array, expected, timeout = 2)
      return if await(timeout) { array.length == expected }
      flunk "Array expected to be #{expected} items but was #{array}"
    end

    def await_array_minimum_length(array, expected, timeout = 2)
      return if await(timeout) { array.length >= expected }
      flunk "Array expected to be at least #{expected} items but was #{array}"
    end

    def await_criteria(timeout, failure = nil, &block)
      unless await(timeout, &block)
        failure ||= lambda { "Timed out after #{timeout} seconds" }
        flunk failure.call
      end
    end

    private

    def await(timeout)
      deadline = Time.now + timeout
      while Time.now < deadline
        sleep timeout / 20
        return true if yield
      end
      return false
    end
  end
end
