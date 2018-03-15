require 'test_helper'

class TestOperatorGroupJoin < Minitest::Test
  include Rx::MarbleTesting

  def test_group_where_left_short_lived
    left        = cold('  1-2-4|')
    right       = cold('  -abcd|')
    expected    = msgs('--1-2-3|')
    expected_w1 = msgs('---(a|)')
    expected_w2 = msgs('----(ab)(c|)')
    expected_w3 = msgs('------(bcd)|')

    windows = []
    actual = scheduler.configure do
      left.group_join(
        right,
        lambda { |_| cold('-|') },
        lambda { |_| cold('--|') },
        lambda { |_, s| s }
      ).map do |subject|
        windows << o = scheduler.create_observer
        subject.subscribe(o)
        windows.size
      end
    end
    w1, w2, w3 = windows

    assert_msgs expected, actual
    assert_msgs expected_w1, w1
    assert_msgs expected_w2, w2
    assert_msgs expected_w3, w3
  end

  def test_group_where_right_short_lived
    left        = cold('  1-2-4|')
    right       = cold('  -abcd|')
    expected    = msgs('--1-2-3|')
    expected_w1 = msgs('---a(b|)')
    expected_w2 = msgs('----(ab)c(d|)')
    expected_w3 = msgs('------(cd)-|')

    windows = []
    actual = scheduler.configure do
      left.group_join(
        right,
        lambda { |_| cold('--|') },
        lambda { |_| cold('-|') },
        lambda { |_, s| s }
      ).map do |subject|
        windows << o = scheduler.create_observer
        subject.subscribe(o)
        windows.size
      end
    end
    w1, w2, w3 = windows

    assert_msgs expected, actual
    assert_msgs expected_w1, w1
    assert_msgs expected_w2, w2
    assert_msgs expected_w3, w3
  end

  def test_left_completes_first
    left        = cold('  1-|')
    right       = cold('  -a-b|')
    expected    = msgs('--1-|')
    expected_w1 = msgs('---a|')
    left_subs   = subs('  ^ !')
    right_subs  = subs('  ^ !')

    windows = []
    actual = scheduler.configure do
      left.group_join(
        right,
        lambda { |_| cold('--|') },
        lambda { |_| cold('-') },
        lambda { |_, s| s }
      ).map do |subject|
        windows << o = scheduler.create_observer
        subject.subscribe(o)
        windows.size
      end
    end
    w1, = windows

    assert_msgs expected, actual
    assert_msgs expected_w1, w1
    assert_subs left_subs, left
    assert_subs right_subs, right
  end

  def test_ignore_completing_right
    left        = cold('  1--2|')
    right       = cold('  -a|')
    expected    = msgs('--1--2|')
    expected_w1 = msgs('---(a|)')
    expected_w2 = msgs('-----a|')
    left_subs   = subs('  ^   !')
    right_subs  = subs('  ^   !')

    windows = []
    actual = scheduler.configure do
      left.group_join(
        right,
        lambda { |_| cold('-|') },
        lambda { |_| cold('-') },
        lambda { |_, s| s }
      ).map do |subject|
        windows << o = scheduler.create_observer
        subject.subscribe(o)
        windows.size
      end
    end
    w1, w2 = windows

    assert_msgs expected, actual
    assert_msgs expected_w1, w1
    assert_msgs expected_w2, w2
    assert_subs left_subs, left
    assert_subs right_subs, right
  end

  def test_left_selector_completes_immediately
    left        = cold('  -1-|')
    right       = cold('  ab-|')
    expected    = msgs('---1-|')
    expected_w1 = msgs('---(ab|)')
    left_subs   = subs('  ^  !')
    right_subs  = subs('  ^  !')

    windows = []
    actual = scheduler.configure do
      left.group_join(
        right,
        lambda { |_| cold('|') },
        lambda { |_| cold('-') },
        lambda { |_, s| s }
      ).map do |subject|
        windows << o = scheduler.create_observer
        subject.subscribe(o)
        windows.size
      end
    end
    w1, = windows

    assert_msgs expected, actual
    assert_msgs expected_w1, w1
    assert_subs left_subs, left
    assert_subs right_subs, right
  end

  def test_left_selector_never_completes
    left        = cold('  -1-|')
    right       = cold('  ab-|')
    expected    = msgs('---1-|')
    expected_w1 = msgs('---b--')
    left_subs   = subs('  ^   ')
    right_subs  = subs('  ^   ')

    windows = []
    actual = scheduler.configure do
      left.group_join(
        right,
        lambda { |_| cold('-') },
        lambda { |_| cold('|') },
        lambda { |_, s| s }
      ).map do |subject|
        windows << o = scheduler.create_observer
        subject.subscribe(o)
        windows.size
      end
    end
    w1, = windows

    assert_msgs expected, actual
    assert_msgs expected_w1, w1
    assert_subs left_subs, left
    assert_subs right_subs, right
  end

  def test_duration_selectors_arguments
    left        = cold('  1|')
    right       = cold('  -a|')

    scheduler.configure do
      left.group_join(
        right,
        lambda do |l|
          assert_equal 1, l
          cold('|')
        end,
        lambda do |r|
          asser_equal 'a', r
          cold('|')
        end,
        lambda { |_, s| s }
      )
    end
  end

  def test_propagate_left_error
    left        = cold('  -#')
    right       = cold('  1-')
    expected    = msgs('---#')

    actual = scheduler.configure do
      left.group_join(
        right,
        lambda { |_| cold('-|') },
        lambda { |_| cold('--|') },
        lambda { |_, s| s }
      )
    end

    assert_msgs expected, actual
  end

  def test_propagate_right_error
    left        = cold('  1-')
    right       = cold('  -#')
    expected    = msgs('--1#')
    expected_w1 = msgs('---#')
    left_subs   = subs('  ^!')

    windows = []
    actual = scheduler.configure do
      left.group_join(
        right,
        lambda { |_| cold('--|') },
        lambda { |_| cold('--|') },
        lambda { |_, s| s }
      ).map do |subject|
        windows << o = scheduler.create_observer
        subject.subscribe(o)
        windows.size
      end
    end
    w1, = windows

    assert_msgs expected, actual
    assert_msgs expected_w1, w1
    assert_subs left_subs, left
  end

  def test_propagate_left_duration_error
    left        = cold('  -1')
    right       = cold('  a-')
    expected    = msgs('---(1#)')
    expected_w1 = msgs('---(a#)')

    windows = []
    actual = scheduler.configure do
      left.group_join(
        right,
        lambda { |_| cold('#') },
        lambda { |_| cold('--|') },
        lambda { |_, s| s }
      ).map do |subject|
        windows << o = scheduler.create_observer
        subject.subscribe(o)
        windows.size
      end
    end
    w1, = windows

    assert_msgs expected, actual
    assert_msgs expected_w1, w1
  end

  def test_propagate_right_duration_error
    left        = cold('  1-')
    right       = cold('  -a')
    expected    = msgs('--1#')
    expected_w1 = msgs('---(a#)')

    windows = []
    actual = scheduler.configure do
      left.group_join(
        right,
        lambda { |_| cold('-') },
        lambda { |_| cold('#') },
        lambda { |_, s| s }
      ).map do |subject|
        windows << o = scheduler.create_observer
        subject.subscribe(o)
        windows.size
      end
    end
    w1, = windows

    assert_msgs expected, actual
    assert_msgs expected_w1, w1
  end

  def test_propagate_left_duration_raises
    left        = cold('  1')
    right       = cold('  --')
    expected    = msgs('--(1#)')
    expected_w1 = msgs('--#')

    windows = []
    actual = scheduler.configure do
      left.group_join(
        right,
        lambda { |_| raise error },
        lambda { |_| cold('-') },
        lambda { |_, s| s }
      ).map do |subject|
        windows << o = scheduler.create_observer
        subject.subscribe(o)
        windows.size
      end
    end
    w1, = windows

    assert_msgs expected, actual
    assert_msgs expected_w1, w1
  end

  def test_propagate_right_duration_raises
    left        = cold('  1-')
    right       = cold('  -a')
    expected    = msgs('--1#')
    expected_w1 = msgs('---#')

    windows = []
    actual = scheduler.configure do
      left.group_join(
        right,
        lambda { |_| cold('-') },
        lambda { |_| raise error },
        lambda { |_, s| s }
      ).map do |subject|
        windows << o = scheduler.create_observer
        subject.subscribe(o)
        windows.size
      end
    end
    w1, = windows

    assert_msgs expected, actual
    assert_msgs expected_w1, w1
  end

  def test_propagate_result_selector_raises
    left        = cold('  1-')
    right       = cold('  -a')
    expected    = msgs('--#')

    actual = scheduler.configure do
      left.group_join(
        right,
        lambda { |_| cold('-') },
        lambda { |_| cold('-') },
        lambda { |_, s| raise error }
      )
    end

    assert_msgs expected, actual
  end
end
