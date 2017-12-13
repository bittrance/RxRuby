require 'test_helper'

class TestOperatorOnErrorResumeNext < Minitest::Test
  include Rx::MarbleTesting

  def test_resumes_next_on_left_error
    left       = cold('  -1#')
    right      = cold('    -2|')
    expected   = msgs('---1-2|')
    left_subs  = subs('  ^ !')
    right_subs = subs('    ^ !')

    actual = scheduler.configure do
      left.on_error_resume_next(right)
    end

    assert_msgs expected, actual
    assert_subs left_subs, left
    assert_subs right_subs, right
  end

  def test_completes_on_right_error
    left       = cold('  -1|')
    right      = cold('    -2#')
    expected   = msgs('---1-2|')
    left_subs  = subs('  ^ !')
    right_subs = subs('    ^ !')

    actual = scheduler.configure do
      left.on_error_resume_next(right)
    end

    assert_msgs expected, actual
    assert_subs left_subs, left
    assert_subs right_subs, right
  end

  def test_resumes_next_continues_on_complete
    left       = cold('  -1|')
    right      = cold('    -2|')
    expected   = msgs('---1-2|')
    left_subs  = subs('  ^ !')
    right_subs = subs('    ^ !')

    actual = scheduler.configure do
      left.on_error_resume_next(right)
    end

    assert_msgs expected, actual
    assert_subs left_subs, left
    assert_subs right_subs, right
  end

  def test_right_cannot_be_nil
    left = cold('  -1|')
    assert_raises(ArgumentError) do
      left.on_error_resume_next(nil)
    end
  end

  def test_accepts_enumerator
    left       = cold('  -1#')
    right      = cold('    -2|')
    expected   = msgs('---1-2|')
    left_subs  = subs('  ^ !')
    right_subs = subs('    ^ !')

    enum = Enumerator.new do |y|
      y << left
      y << right
    end

    actual = scheduler.configure do
      Rx::Observable.on_error_resume_next(enum)
    end

    assert_msgs expected, actual
    assert_subs left_subs, left
    assert_subs right_subs, right
  end

  def test_erroring_enumerator
    expected = msgs('--#')
    enum = Enumerator.new do |y|
      raise error
    end

    actual = scheduler.configure do
      Rx::Observable.on_error_resume_next(enum)
    end

    assert_msgs expected, actual
  end
end
