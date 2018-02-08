require 'test_helper'

class TestOperatorToH < Minitest::Test
  include Rx::MarbleTesting

  def test_collects_sequence_into_hash_on_complete
    result = {'a' => 'a', 'b' => 'b', 'c' => 'c'}
    source      = cold('  -abc|')
    expected    = msgs('------(a|)', a: result)
    source_subs = subs('  ^   !')

    actual = scheduler.configure { source.to_h }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_block_selects_hash_key
    result = {'1' => 1, '2' => 2, '3' => 3}
    source      = cold('  -123|')
    expected    = msgs('------(a|)', a: result)
    source_subs = subs('  ^   !')

    actual = scheduler.configure do
      source.to_h do |c|
        c.key_selector { |k| k.to_s }
      end
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_block_selects_hash_value
    n = 0
    result = {'a' => 1, 'b' => 2, 'c' => 3}
    source      = cold('  -abc|')
    expected    = msgs('------(a|)', a: result)
    source_subs = subs('  ^   !')

    actual = scheduler.configure do
      source.to_h do |c|
        c.value_selector { |v| n += 1 }
      end
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_erroring_key_block
    source      = cold('  -1')
    expected    = msgs('---#')
    source_subs = subs('  ^!')

    actual = scheduler.configure do
      source.to_h do |c|
        c.key_selector { |v| raise error }
      end
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  
  def test_erroring_value_block
    source      = cold('  -1')
    expected    = msgs('---#')
    source_subs = subs('  ^!')

    actual = scheduler.configure do
      source.to_h do |c|
        c.value_selector { |v| raise error }
      end
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_propagates_error
    source      = cold('  -#')
    expected    = msgs('---#')
    source_subs = subs('  ^!')

    actual = scheduler.configure { source.to_h }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_selector_configuration_fails_immediately
    source = cold('  -|')
    assert_raises(RuntimeError) do
      source.to_h { |_| raise error }
    end
  end
end