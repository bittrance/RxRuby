require 'test_helper'

class TestCombineLatest < Minitest::Test
  include Rx::MarbleTesting

  def test_apply_selector_before_emission
    left         = cold('  -123--|')
    right        = cold('  ----4-|')
    expected     = msgs('------7-|')
    left_subs    = subs('--^-----!')
    right_subs   = subs('--^-----!')

    actual = scheduler.configure do
      left.combine_latest(right) { |*values| values.map(&:to_i).inject(0, :+).to_s }
    end

    assert_msgs expected, actual
    assert_subs left_subs, left
    assert_subs right_subs, right
  end
end

class TestObservableCombineLatest < Minitest::Test
  include Rx::MarbleTesting

  def test_emit_when_all_source_omitted_once
    a        = cold('  -1----4|')
    b        = cold('  --2--5|')
    c        = cold('  ---36|')
    expected = msgs('-----abcd|', a: %w[1 2 3], b: %w[1 2 6], c: %w[1 5 6], d: %w[4 5 6])
    a_subs   = subs('--^------!')
    b_subs   = subs('--^-----!')
    c_subs   = subs('--^----!')

    actual = scheduler.configure do
      Rx::Observable.combine_latest(a, b, c)
    end

    assert_msgs expected, actual
    assert_subs a_subs, a
    assert_subs b_subs, b
    assert_subs c_subs, c
  end

  def test_emit_only_latest_from_each_source
    a        = cold('  -123--|')
    b        = cold('  ----4-|')
    expected = msgs('------a-|', a: %w[3 4])
    a_subs   = subs('--^-----!')
    b_subs   = subs('--^-----!')

    actual = scheduler.configure do
      Rx::Observable.combine_latest(a, b)
    end

    assert_msgs expected, actual
    assert_subs a_subs, a
    assert_subs b_subs, b
  end

  def test_retain_last_for_completed_sources
    a        = cold('  -1-----5|')
    b        = cold('  --2--4|')
    c        = cold('  ---3|')
    expected = msgs('-----a-b-c|', a: %w[1 2 3], b: %w[1 4 3], c: %w[5 4 3])
    a_subs   = subs('--^-------!')
    b_subs   = subs('--^-----!')
    c_subs   = subs('--^---!')

    actual = scheduler.configure(disposed: 2000) do
      Rx::Observable.combine_latest(a, b, c)
    end

    assert_msgs expected, actual
    assert_subs a_subs, a
    assert_subs b_subs, b
    assert_subs c_subs, c
  end

  def test_source_error_is_propagated
    a        = cold('  -1--|')
    b        = cold('  --#')
    expected = msgs('----#')
    a_subs   = subs('--^-!')
    b_subs   = subs('--^-!')

    actual = scheduler.configure do
      Rx::Observable.combine_latest(a, b)
    end

    assert_msgs expected, actual
    assert_subs a_subs, a
    assert_subs b_subs, b
  end

  def test_completes_immediately_on_empty_source
    a        = cold('  -|')
    expected = msgs('---|')
    a_subs   = subs('--^!')

    actual = scheduler.configure do
      Rx::Observable.combine_latest(a)
    end

    assert_msgs expected, actual
    assert_subs a_subs, a
  end

  def test_completes_without_emitting_when_some_emits
    a        = cold('  -1-2-|')
    b        = cold('  --|')
    expected = msgs('-----|')
    a_subs   = subs('--^--!')
    b_subs   = subs('--^-!')

    actual = scheduler.configure do
      Rx::Observable.combine_latest(a, b)
    end

    assert_msgs expected, actual
    assert_subs a_subs, a
    assert_subs b_subs, b
  end

  def test_apply_selector_before_emission
    a        = cold('  -123--|')
    b        = cold('  ----4-|')
    expected = msgs('------7-|')
    a_subs   = subs('--^-----!')
    b_subs   = subs('--^-----!')

    actual = scheduler.configure do
      Rx::Observable.combine_latest(a, b) { |*values| values.map(&:to_i).inject(0, :+).to_s }
    end

    assert_msgs expected, actual
    assert_subs a_subs, a
    assert_subs b_subs, b
  end

  def test_propagate_error_raised_in_selector
    a        = cold('  -123--|')
    b        = cold('  ----4-|')
    expected = msgs('------#')
    a_subs   = subs('--^---!')
    b_subs   = subs('--^---!')

    actual = scheduler.configure do
      Rx::Observable.combine_latest(a, b) { |_| raise error }
    end

    assert_msgs expected, actual
    assert_subs a_subs, a
    assert_subs b_subs, b
  end
end
