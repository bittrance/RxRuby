require 'test_helper'

class TestOperatorDelayWithSelector < Minitest::Test
  include Rx::MarbleTesting

  def test_delay_values_on_selector_value
    delay1      = cold('   -|')
    delay2      = cold('    --1|')
    delay3      = cold('     ---|')
    source      = cold('  -123|')
    expected    = msgs('----1-2-(3|)')
    source_subs = subs('  ^   !')
    delay1_subs = subs('   ^!')
    delay2_subs = subs('    ^ !')
    delay3_subs = subs('     ^  !')

    delays = [delay1, delay2, delay3]
    actual = scheduler.configure do
      source.delay_with_selector { |v| delays.shift }
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
    assert_subs delay1_subs, delay1
    assert_subs delay2_subs, delay2
    assert_subs delay3_subs, delay3
  end

  def test_delay_source_subscription
    delay1      = cold('  --|')
    delay2      = cold('     --|')
    source      = cold('    -1|')
    expected    = msgs('-------(1|)')
    source_subs = subs('    ^ !')
    delay1_subs = subs('  ^ !')
    delay2_subs = subs('     ^ !')

    actual = scheduler.configure do
      source.delay_with_selector(delay1) { |v| delay2 }
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
    assert_subs delay1_subs, delay1
    assert_subs delay2_subs, delay2
  end

  def test_propagates_error
    source      = cold('  -#')
    expected    = msgs('---#')
    source_subs = subs('  ^!')

    actual = scheduler.configure do
      source.delay_with_selector { cold('--|') }
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_erroring_selector
    source      = cold('  -1')
    expected    = msgs('---#')
    source_subs = subs('  ^!')

    actual = scheduler.configure do
      source.delay_with_selector { |v| cold('#') }
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_erroring_subscription_delay
    delay       = cold('  -#')
    source      = cold('   -1')
    expected    = msgs('---#')
    source_subs = subs('')

    actual = scheduler.configure do
      source.delay_with_selector(delay) { |v| }
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_selector_raises
    source      = cold('  -1')
    expected    = msgs('---#')
    source_subs = subs('  ^!')

    actual = scheduler.configure do
      source.delay_with_selector { raise error }
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_argument_error_when_no_block
    source = cold('-|')
    assert_raises(ArgumentError) do
      source.delay_with_selector
    end
  end
end
