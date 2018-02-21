require 'test_helper'

class TestOperatorConcatAll < Minitest::Test
  include Rx::MarbleTesting

  def test_concat_sequences
    a           = cold('  12-|')
    b           = cold('     3-4|')
    source      = cold('  ab|', a: a, b: b)
    expected    = msgs('--12-3-4|')
    a_subs      = subs('--^--!')
    b_subs      = subs('-----^--!')
    source_subs = subs('--^-----!') # FIXME: should unsubscribe 400

    actual = scheduler.configure { source.concat_all }

    assert_msgs expected, actual
    assert_subs a_subs, a
    assert_subs b_subs, b
    assert_subs source_subs, source
  end
end