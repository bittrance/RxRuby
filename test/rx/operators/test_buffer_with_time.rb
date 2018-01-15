require 'test_helper'

class TestOperatorBufferWithTime < Minitest::Test
  include Rx::MarbleTesting

  def test_elements_gathered_into_arrays
    source      = cold('  -12345|')
    expected    = msgs('-----a--(b|)', a: [1, 2], b: [3, 4, 5])
    source_subs = subs('  ^     !')

    actual = scheduler.configure { source.buffer_with_time(300, 300, scheduler) }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_empty_arrays_for_quiet_intervals
    source      = cold('  -12---|')
    expected    = msgs('-----a--(b|)', a: [1, 2], b: [])
    source_subs = subs('  ^     !')

    actual = scheduler.configure { source.buffer_with_time(300, 300, scheduler) }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_overlapping_arrays_on_small_shift
    source      = cold('  -123456789|')
    # b is four elements because first windod_with_time schedule occurs before cold observer
    expected    = msgs('-----a-b-c-d(e|)', a: [1, 2], b: [2, 3, 4, 5], c: [5, 6, 7], d: [7, 8, 9], e: [9])
    source_subs = subs('  ^         !')

    actual = scheduler.configure(disposed: 1500) { source.buffer_with_time(300, 200, scheduler) }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_non_contiguous_arrays_on_large_shift
    source      = cold('  -123456|')
    expected    = msgs('-----a---(b|)', a: [1, 2], b: [5, 6])
    source_subs = subs('  ^      !')

    actual = scheduler.configure { source.buffer_with_time(300, 500, scheduler) }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_propagates_error
    source      = cold('  -#')
    expected    = msgs('---#')
    source_subs = subs('  ^!')

    actual = scheduler.configure { source.buffer_with_time(300) }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_propagates_completion
    source      = cold('  |')
    expected    = msgs('--(a|)', a: [])
    source_subs = subs('  (^!)')

    actual = scheduler.configure { source.buffer_with_time(300) }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_count_must_be_positive
    source = cold('  -1|')
    assert_raises(ArgumentError) do
      source.buffer_with_time(0)
    end
  end

  def test_skip_must_be_poitive
    source = cold('  -1|')
    assert_raises(ArgumentError) do
      source.buffer_with_time(300, 0)
    end
  end
end
