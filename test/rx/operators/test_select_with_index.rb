require 'test_helper'

class TestOperatorSelect < Minitest::Test
  include Rx::MarbleTesting

  def test_replaces_value_with_block_result
    source      = cold('  -123456|')
    expected    = msgs('----2-4-6|')
    source_subs = subs('  ^      !')

    actual = scheduler.configure do
      source.select { |x| x % 2 == 0 }
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
  end
end

class TestOperatorSelectWithIndex < Minitest::Test
  include Rx::MarbleTesting

  def test_block_filters_values
    source      = cold('  -11335|')
    expected    = msgs('---1-3-5|')
    source_subs = subs('  ^     !')

    actual = scheduler.configure do
      source.select_with_index { |x, i| x > i }
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_respects_nil_as_a_value
    source      = cold('  -a|', a: nil)
    expected    = msgs('---a|', a: nil)
    source_subs = subs('  ^ !')

    actual = scheduler.configure do
      source.select_with_index { |x, _| true }
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_erroring_block
    source      = cold('  -1')
    expected    = msgs('---#')
    source_subs = subs('  ^!')

    actual = scheduler.configure do
      source.select_with_index { raise error }
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_propagates_error
    source      = cold('  -#')
    expected    = msgs('---#')
    source_subs = subs('  ^!')

    actual = scheduler.configure do
      source.select_with_index { |x, i| [i, x] }
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
  end
end