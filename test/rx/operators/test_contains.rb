require 'test_helper'

class TestOperatorContains < Minitest::Test
  include Rx::MarbleTesting

  class This
    def ==(other)
      false
    end

    def eql?(other)
      other.is_a? This
    end
  end

  class That
    def ==(other)
      false
    end

    def eql?(other)
      other.is_a? That
    end
  end

  def test_emit_true_on_first_eql_match
    source       = cold('  -aba|', a: That.new, b: This.new)
    expected     = msgs('----(t|)', t: true)
    source_subs  = subs('  ^ !')

    actual = scheduler.configure { source.contains?(This.new) }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_emit_false_when_no_eql_match
    source       = cold('  -aaa|', a: That.new)
    expected     = msgs('------(f|)', f: false)
    source_subs  = subs('  ^   !')

    actual = scheduler.configure { source.contains?(This.new) }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_emit_false_on_empty
    source       = cold('  -|')
    expected     = msgs('---(f|)', f: false)
    source_subs  = subs('  ^!')

    actual = scheduler.configure { source.contains?(This.new) }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_propagates_error
    source       = cold('  -#')
    expected     = msgs('---#')
    source_subs  = subs('  ^!')

    actual = scheduler.configure { source.contains?('foo') }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end
end