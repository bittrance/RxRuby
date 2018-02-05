require 'test_helper'

class TestOperatorSkipLast < Minitest::Test
  include Rx::MarbleTesting

  def test_skip_last_emitted_values
    source      = cold('  -123456|')
    expected    = msgs('------123|')
    source_subs = subs('  ^      !')

    actual = scheduler.configure { source.skip_last(3) }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_emits_nothing_when_fewer_than_count
    source      = cold('  -123|')
    expected    = msgs('------|')
    source_subs = subs('  ^   !')

    actual = scheduler.configure { source.skip_last(3) }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_propagates_error
    source      = cold('  -#')
    expected    = msgs('---#')
    source_subs = subs('  ^!')

    actual = scheduler.configure { source.skip_last(3) }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_propagates_completion
    source      = cold('  -|')
    expected    = msgs('---|')
    source_subs = subs('  ^!')

    actual = scheduler.configure { source.skip_last(3) }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_argument_error_on_negative_count
    source = cold('  -|')
    assert_raises(ArgumentError) do
      source.skip_last(-1)
    end
  end
end
