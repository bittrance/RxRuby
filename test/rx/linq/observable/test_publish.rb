require 'test_helper'

class TestOperatorPublish < Minitest::Test
  include Rx::MarbleTesting

  def test_single_subject
    # Note manual subscribe @ 100
    source      = cold(' -123|')
    expected    = msgs('--123|')
    source_subs = subs('-^---!')

    actual = scheduler.configure do
      obs = source.publish
      obs.connect
      obs
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_subject_selector
    source      = cold('  -123|')
    expected    = msgs('---234|')
    source_subs = subs('--^---!')

    actual = scheduler.configure do
      source.publish do |connectable|
        connectable.connect
        connectable.map { |n| n + 1 }
      end
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
  end
end