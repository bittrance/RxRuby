require 'test_helper'

class TestOperatorConcatMapObserver < Minitest::Test
  include Rx::MarbleTesting

  def test_map_with_index
    source      = cold('  123|')
    expected    = msgs('--135|')
    source_subs = subs('--^--!')

    actual = scheduler.configure do
      source.concat_map_observer(
        lambda { |x, i| cold("#{x + i}|") },
        lambda { |err| err },
        lambda { cold('|') },
      )
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_next_raises
    source      = cold('  1|')
    expected    = msgs('--#')
    source_subs = subs('--(^!)')

    actual = scheduler.configure do
      source.concat_map_observer(
        lambda { |x, i| raise error },
        lambda { |err| },
        lambda { },
      )
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_handle_error
    source      = cold('  -#')
    expected    = msgs('---a|')
    source_subs = subs('--^!')

    actual = scheduler.configure do
      source.concat_map_observer(
        lambda { |x, i| },
        lambda { |err| cold('a|') },
        lambda { },
      )
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_map_error_raises
    other_err   = RuntimeError.new
    source      = cold('  -#')
    expected    = msgs('---#', error: other_err)
    source_subs = subs('--^!')

    actual = scheduler.configure do
      source.concat_map_observer(
        lambda { |x, i| },
        lambda { |err| raise other_err },
        lambda { },
      )
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_handle_completion
    source      = cold('  -|')
    expected    = msgs('---a|')
    source_subs = subs('--^!')

    actual = scheduler.configure do
      source.concat_map_observer(
        lambda { |x, i| },
        lambda { |err| },
        lambda { cold('a|') },
      )
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_completion_raises
    source      = cold('  -|')
    expected    = msgs('---#')
    source_subs = subs('--^!')

    actual = scheduler.configure do
      source.concat_map_observer(
        lambda { |x, i| },
        lambda { |err| },
        lambda { raise error },
      )
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
  end
end