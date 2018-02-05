require 'test_helper'

class TestOperatorEnsures < Minitest::Test
  include Rx::MarbleTesting

  def test_block_executes_at_unsubscribe
    source      = cold('  -123---1')
    expected    = msgs('---123--')
    source_subs = subs('  ^    !')

    ts = nil
    actual = scheduler.configure(disposed: 700) do
      source.ensures { ts = scheduler.now }
    end

    assert_equal 700, ts
    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_block_executes_at_error_because_autodetach
    source      = cold('  -#')
    expected    = msgs('---#')
    source_subs = subs('  ^!')

    ts = nil
    actual = scheduler.configure do
      source.ensures { ts = scheduler.now }
    end

    assert_equal 300, ts
    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_block_executes_on_completed
    source      = cold('  -|')
    expected    = msgs('---|')
    source_subs = subs('  ^!')

    ts = nil
    actual = scheduler.configure do
      source.ensures { ts = scheduler.now }
    end

    assert_equal 300, ts
    assert_msgs expected, actual
    assert_subs source_subs, source
  end
end