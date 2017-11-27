require 'test_helper'

module Rx
  class TestThreadedEnumerator < Minitest::Test
    def setup
      @enum = ThreadedEnumerator.new do |y|
        y << 1
        y << 2
        y << 3
      end
    end

    def test_returns_next_element
      assert_equal 1, @enum.next
      assert_equal 2, @enum.next
      assert_equal 3, @enum.next
    end

    def test_raises_stop_iteration
      3.times { @enum.next }
      assert_raises(StopIteration) { @enum.next }
      assert_raises(StopIteration) { @enum.next }
    end

    def test_propagates_errors_from_yielder_thread
      enum = ThreadedEnumerator.new do |y|
        raise RuntimeError.new
      end
      assert_raises(RuntimeError) { enum.next }
    end

    def test_called_across_threads
      result = []
      3.times { Thread.new { result << @enum.next }.join }
      assert_equal [1, 2, 3], result
    end

    def test_slow_yield
      enum = ThreadedEnumerator.new do |y|
        (1..3).each { |n| sleep 0.01 ; y << n }
      end
      3.times { enum.next }
      assert_raises(StopIteration) { enum.next }
    end

    def test_slow_poll
      3.times { sleep 0.01 ; @enum.next }
      assert_raises(StopIteration) { @enum.next }
      assert_raises(StopIteration) { @enum.next }
    end

    def test_construct_from_enumerable
      enum = ThreadedEnumerator.new([1, 2, 3])
      assert_equal [1, 2, 3], 3.times.map { enum.next }
      assert_raises(StopIteration) { enum.next }
    end

    def test_argument_error_on_both_block_and_source
      assert_raises(ArgumentError) { ThreadedEnumerator.new([]) { } }
    end
  end
end
