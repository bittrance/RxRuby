require 'test_helper'

class TestOperatorTimeout < Minitest::Test
  include Rx::MarbleTesting

  def test_on_infinite_and_empty
    err_check = ->(e) { e.is_a? Rx::TimeoutError }
    source      = cold('')
    expected    = msgs('----#', error: err_check)
    source_subs = subs('  ^ !')

    actual = scheduler.configure do
      source.timeout(200, scheduler)
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_values_delay_timeout
    err_check = ->(e) { e.is_a? Rx::TimeoutError }
    source      = cold('  -1')
    expected    = msgs('---1-#', error: err_check)
    source_subs = subs('  ^  !')

    actual = scheduler.configure do
      source.timeout(200, scheduler)
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_propagates_completion
    source      = cold('  -|')
    expected    = msgs('---|')
    source_subs = subs('  ^!')

    actual = scheduler.configure do
      source.timeout(200, scheduler)
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_propagates_error
    source      = cold('  -#')
    expected    = msgs('---#')
    source_subs = subs('  ^!')

    actual = scheduler.configure do
      source.timeout(200, scheduler)
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_absolute_deadline_non_completing
    err_check = ->(e) { e.is_a? Rx::TimeoutError }
    source      = cold('  -1-|')
    expected    = msgs('---1#', error: err_check)
    source_subs = subs('  ^ !')

    actual = scheduler.configure do
      source.timeout(Rx::TestTime.new(400), scheduler)
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_absolute_deadline_completing
    source      = cold('  -|')
    expected    = msgs('---|')
    source_subs = subs('  ^!')

    actual = scheduler.configure do
      source.timeout(Rx::TestTime.new(400), scheduler)
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
  end
end
