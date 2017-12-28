require 'test_helper'

class TestOperatorRetry < Minitest::Test
  include Rx::MarbleTesting

  def test_retries_when_left_erroring
    source      = cold('  -12#')
    expected    = msgs('---12-12#')
    source_subs = subs('  ^  (!^)  !')

    actual = scheduler.configure { source .retry(2) }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_does_not_retry_without_error
    source      = cold('  -12|')
    expected    = msgs('---12|')
    source_subs = subs('  ^  !')

    actual = scheduler.configure { source.retry(2) }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end
end
