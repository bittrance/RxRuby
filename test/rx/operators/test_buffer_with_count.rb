require 'test_helper'

class TestOperatorBufferWithCount < Minitest::Test
  include Rx::MarbleTesting

  def test_outputs_elements_gathered_into_arrays
    source      = cold('  -123456|')
    expected    = msgs('-----a--b|', a: [1, 2, 3], b: [4, 5, 6])
    source_subs = subs('  ^      !')

    actual = scheduler.configure { source.buffer_with_count(3) }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_outputs_trailing_buffer
    source      = cold('  -1234|')
    expected    = msgs('-----a-(b|)', a: [1, 2, 3], b: [4])
    source_subs = subs('  ^    !')

    actual = scheduler.configure { source.buffer_with_count(3) }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_overlapping_arrays_on_small_skip
    source      = cold('  -123456|')
    expected    = msgs('-----a-b-(c|)', a: [1, 2, 3], b: [3, 4, 5], c: [5, 6])
    source_subs = subs('  ^      !')

    actual = scheduler.configure { source.buffer_with_count(3, 2) }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_propagates_error
    source      = cold('  -#')
    expected    = msgs('---#')
    source_subs = subs('  ^!')

    actual = scheduler.configure { source.buffer_with_count(3) }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_propagates_completion
    source      = cold('  -|')
    expected    = msgs('---|')
    source_subs = subs('  ^!')

    actual = scheduler.configure { source.buffer_with_count(3) }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end
  
  def test_count_must_be_positive
    source = cold('  -1|')
    assert_raises(ArgumentError) do
      source.buffer_with_count(0)
    end
  end

  def test_skip_must_be_poitive
    source = cold('  -1|')
    assert_raises(ArgumentError) do
      source.buffer_with_count(3, 0)
    end
  end
end