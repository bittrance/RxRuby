require 'test_helper'

class TestOperatorAverage < Minitest::Test
  include Rx::MarbleTesting
  
  def test_calculates_average_of_emitted_values
    source       = cold('  -2424|')
    expected     = msgs('-------(3|)')
    source_subs  = subs('  ^    !')

    actual = scheduler.configure { source.average }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_maps_with_block
    source       = cold('  -2424|')
    expected     = msgs('-------(4|)')
    source_subs  = subs('  ^    !')

    actual = scheduler.configure do
      source.average { |n| n + 1 }
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_erroring_block
    source       = cold('  -2424|')
    expected     = msgs('---#')
    source_subs  = subs('  ^!')

    actual = scheduler.configure do
      source.average { |n| raise error }
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_propagates_error
    source       = cold('  -2#')
    expected     = msgs('----#')
    source_subs  = subs('  ^ !')

    actual = scheduler.configure { source.average }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_fails_on_non_numerical_values
    my_err = ->(err) { err.is_a?(TypeError) && err.message.match(/blah.*numerical/) }

    source       = cold('  -a', a: 'blah')
    expected     = msgs('---#', error: my_err)
    source_subs  = subs('  ^!')

    actual = scheduler.configure { source.average }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_fails_on_empty_sequence
    my_err = ->(err) { err.is_a?(RuntimeError) && err.message.include?('no elements') }

    source       = cold('  -|')
    expected     = msgs('---#', error: my_err)
    source_subs  = subs('  ^!')

    actual = scheduler.configure { source.average }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end
end