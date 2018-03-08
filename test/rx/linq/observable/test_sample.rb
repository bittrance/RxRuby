require 'test_helper'

class TestOperatorSample < Minitest::Test
  include Rx::MarbleTesting

  def test_sampler_completes_first
    left       = cold('  1-2-3-')
    right      = cold('  -1-1-1|')
    expected   = msgs('---1-2-3|')
    left_subs  = subs('  ^     !')
    right_subs = subs('  ^     !')

    actual = scheduler.configure do
      left.sample(right)
    end

    assert_msgs expected, actual
    assert_subs left_subs, left
    assert_subs right_subs, right
  end

  def test_source_completes_first
    left       = cold('  1-2-3-4|')
    right      = cold('  -----1-')
    expected   = msgs('-------3-|')
    left_subs  = subs('  ^      !')
    right_subs = subs('  ^      !')

    actual = scheduler.configure do
      left.sample(right)
    end

    assert_msgs expected, actual
    assert_subs left_subs, left
    assert_subs right_subs, right
  end

  def test_respect_nil
    left       = cold('  n-1-n-|', n: nil)
    right      = cold('  -n-1-n|', n: nil)
    expected   = msgs('---n-1-n|', n: nil)

    actual = scheduler.configure { left.sample(right) }

    assert_msgs expected, actual
  end

  def test_with_recipe
    res = scheduler.configure do
      scheduler.create_cold_observable(
        on_next(100, 'left'),
        on_completed(200)
      ).sample(
        scheduler.create_cold_observable(
          on_next(150, 'right'),
          on_completed(200)
        )
      ) { |left, right| [left, right] }
    end

    msgs = [
      on_next(SUBSCRIBED + 150, ['left', 'right']),
      on_completed(400)
    ]
    assert_messages msgs, res.messages
  end

  def test_source_errors
    sampler = nil
    res = scheduler.configure do
      sampler = scheduler.create_cold_observable(
        on_next(50, 1),
        on_completed(200)
      )

      scheduler.create_cold_observable(
        on_error(100, 'badness')
      ).sample(sampler)
    end

    msgs = [on_error(SUBSCRIBED + 100, 'badness')]
    assert_messages msgs, res.messages
  end

  def test_sampler_errors
    res = scheduler.configure do
      sampler = scheduler.create_cold_observable(
        on_error(50, 'badness'),
        on_completed(200)
      )

      scheduler.create_cold_observable(
        on_next(100, 1)
      ).sample(sampler)
    end

    msgs = [on_error(250, 'badness')]
    assert_messages msgs, res.messages
  end


  def test_recipe_raises
    left       = cold('  1-')
    right      = cold('  -1')
    expected   = msgs('---#')
    left_subs  = subs('  ^!')
    right_subs = subs('  ^!')

    actual = scheduler.configure do
      left.sample(right) { raise error }
    end

    assert_msgs expected, actual
    assert_subs left_subs, left
    assert_subs right_subs, right
  end
end
