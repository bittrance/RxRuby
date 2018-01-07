require 'test_helper'

class TestOperatorEmpty < Minitest::Test
  include Rx::MarbleTesting
  
  def test_emut_false_for_any_values
    source       = cold('  -a|')
    expected     = msgs('---(f|)', f: false)
    source_subs  = subs('  ^!')

    actual = scheduler.configure { source.empty? }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_true_on_empty
    source       = cold('  -|')
    expected     = msgs('---(t|)', t: true)
    source_subs  = subs('  ^!')

    actual = scheduler.configure { source.empty? }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_propagates_error
    source       = cold('  -#')
    expected     = msgs('---#')
    source_subs  = subs('  ^!')

    actual = scheduler.configure { source.empty? }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end
end