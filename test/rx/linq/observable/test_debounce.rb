require 'test_helper'

class TestDebounce < Minitest::Test
  include Rx::MarbleTesting

  def test_delay_items_by_due_time
    source      = cold('  -1--2--|')
    expected    = msgs('-----1--2|')
    source_subs = subs('  ^      !')

    actual = scheduler.configure { source.debounce(200, scheduler) }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_emit_latest_value_after_quiet_period
    source      = cold('  -1234--|')
    expected    = msgs('--------4|')
    source_subs = subs('  ^      !')

    actual = scheduler.configure(disposed: 1500) do
      source.debounce(200, scheduler)
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_emit_latest_value_on_completion
    source      = cold('  -12|')
    expected    = msgs('-----(2|)')
    source_subs = subs('  ^  !')

    actual = scheduler.configure { source.debounce(200, scheduler) }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end


  def test_propagate_error
    source      = cold('  -1#')
    expected    = msgs('----#')
    source_subs = subs('  ^ !')

    actual = scheduler.configure { source.debounce(200, scheduler) }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_propagate_completion
    source      = cold('  -|')
    expected    = msgs('---|')
    source_subs = subs('  ^!')

    actual = scheduler.configure { source.debounce(200, scheduler) }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_raises_on_negative_due_time
    source = cold('  -1')
    assert_raises(ArgumentError) do
      source.debounce(-1)
    end
  end
end