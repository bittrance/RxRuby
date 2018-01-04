require 'test_helper'

class TestOperatorCount < Minitest::Test
  include Rx::MarbleTesting
  
  def test_counts_emitted_values
    source       = cold('  -abc|')
    expected     = msgs('------(3|)')
    source_subs  = subs('  ^   !')

    actual = scheduler.configure { source.count }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_counts_only_values_selected_by_block
    source       = cold('  -abc|')
    expected     = msgs('------(2|)')
    source_subs  = subs('  ^   !')

    actual = scheduler.configure do
      source.count { |c| c >= 'b' }
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_propagates_error
    source       = cold('  -a#')
    expected     = msgs('----#')
    source_subs  = subs('  ^ !')

    actual = scheduler.configure { source.count }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_erroring_block
    source       = cold('  -abc|')
    expected     = msgs('---#')
    source_subs  = subs('  ^!')

    actual = scheduler.configure do
      source.count { |c| raise error }
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
  end
end