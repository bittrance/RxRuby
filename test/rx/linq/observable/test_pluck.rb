require 'test_helper'

class TestOperatorPluck < Minitest::Test
  include Rx::MarbleTesting

  def test_emit_property_of_hash
    source      = cold('  ab|', a: {p: 1}, b: {})
    expected    = msgs('--1n|', n: nil)
    source_subs = subs('--^-!')

    actual = scheduler.configure { source.pluck(:p) }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_emit_positional_of_array
    source      = cold('  ab|', a: [0, 1], b: [])
    expected    = msgs('--1n|', n: nil)
    source_subs = subs('--^-!')

    actual = scheduler.configure { source.pluck(1) }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_propagate_error
    source      = cold('  #')
    expected    = msgs('--#')

    actual = scheduler.configure { source.pluck(:p) }

    assert_msgs expected, actual
  end

  def test_propagate_internal_error
    source      = cold('  n|', n: nil)
    expected    = msgs('--#', error: ->(err) { err.is_a? NoMethodError })

    actual = scheduler.configure { source.pluck(:p) }

    assert_msgs expected, actual
  end
end