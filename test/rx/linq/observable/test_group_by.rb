require 'test_helper'

class TestOperatorGroupBy < Minitest::Test
  include Rx::MarbleTesting

  def test_emits_time_limited_subjects
    source      = cold('  12345|')
    expected    = msgs('--xx--x|', x: lambda { |x| x.is_a? Rx::Subject })
    expected_a  = msgs('--5-7|')
    expected_b  = msgs('---6-8|')
    expected_c  = msgs('------9|')
    duration    = cold('---|')

    obs = []
    actual = scheduler.configure do
      source.group_by(
        lambda { |x| x % 2 },
        lambda { |x| x + 4 },
        lambda do |g|
          o = scheduler.create_observer
          obs << o
          g.subscribe(o)
          duration
        end
      )
    end
    a, b, c = obs
    assert_msgs expected, actual
    assert_msgs expected_a, a
    assert_msgs expected_b, b
    assert_msgs expected_c, c
  end

  def test_propagates_error
    source      = cold('  12#')
    expected    = msgs('--xx#', x: lambda { |x| x.is_a? Rx::Subject })
    expected_a  = msgs('--1-#')
    expected_b  = msgs('---2#')

    obs = []
    actual = scheduler.configure do
      source.group_by(
        lambda { |x| x },
        lambda { |x| x },
        lambda do |g|
          o = scheduler.create_observer
          obs << o
          g.subscribe(o)
          cold('')
        end
      )
    end
    a, b = obs

    assert_msgs expected, actual
    assert_msgs expected_a, a
    assert_msgs expected_b, b
  end

  def test_key_selector_raises
    source      = cold('  12')
    expected    = msgs('--x#', x: ->(_) { true })
    expected_s  = msgs('--1#')
    duration    = cold('')

    s = nil
    actual = scheduler.configure do
      source.group_by(
        lambda { |x| raise error if x > 1 ; 1 },
        lambda { |x| x },
        lambda do |g|
          s = scheduler.create_observer
          g.subscribe(s)
          duration
        end
      )
    end
    assert_msgs expected, actual
    assert_msgs expected_s, s
  end

  def test_value_selector_raises
    source      = cold('  12')
    expected    = msgs('--x#', x: ->(_) { true })
    expected_s  = msgs('--1#')
    duration    = cold('')

    s = nil
    actual = scheduler.configure do
      source.group_by(
        lambda { |x| x },
        lambda { |x| raise error if x > 1 ; 1 },
        lambda do |g|
          s = scheduler.create_observer
          g.subscribe(s)
          duration
        end
      )
    end
    assert_msgs expected, actual
    assert_msgs expected_s, s
  end

  def test_duration_selector_raises
    source      = cold('  12|')
    expected    = msgs('--x(x#)', x: ->(_) { true })
    expected_s  = msgs('--1#')
    duration    = cold('')

    s = nil
    n = 0
    actual = scheduler.configure do
      source.group_by(
        lambda { |x| x },
        lambda { |x| x },
        lambda do |g|
          raise error if (n += 1) > 1
          s = scheduler.create_observer
          g.subscribe(s)
          duration
        end
      )
    end
    assert_msgs expected, actual
    assert_msgs expected_s, s
  end

  def test_ignore_duration_selector_values
    source      = cold('  111|')
    expected    = msgs('--x-x|', x: lambda { |x| x.is_a? Rx::Subject })
    expected_a  = msgs('--1(1|)')
    expected_b  = msgs('----1|')
    duration    = cold('2|')

    obs = []
    actual = scheduler.configure do
      source.group_by(
        lambda { |x| x },
        lambda { |x| x },
        lambda do |g|
          o = scheduler.create_observer
          obs << o
          g.subscribe(o)
          duration
        end
      )
    end
    a, b = obs
    assert_msgs expected, actual
    assert_msgs expected_a, a
    assert_msgs expected_b, b
  end

  def test_propagate_duration_selector_error
    source      = cold('  11|')
    expected    = msgs('--xx|', x: lambda { |x| x.is_a? Rx::Subject })
    expected_a  = msgs('--(1#)')
    expected_b  = msgs('---(1#)')
    duration    = cold('#')

    obs = []
    actual = scheduler.configure do
      source.group_by(
        lambda { |x| x },
        lambda { |x| x },
        lambda do |g|
          o = scheduler.create_observer
          obs << o
          g.subscribe(o)
          duration
        end
      )
    end
    a, b = obs
    assert_msgs expected, actual
    assert_msgs expected_a, a
    assert_msgs expected_b, b
  end
end