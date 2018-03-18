require 'test_helper'

class TestOperatorMulticast < Minitest::Test
  include Rx::MarbleTesting

  def test_single_subject
    # Note manual subscribe @ 100
    source      = cold(' -123|')
    expected    = msgs('--123|')
    source_subs = subs('-^---!')

    subject_obs = scheduler.create_observer
    actual = scheduler.configure do
      subject = Rx::Subject.new
      subject.subscribe(subject_obs)
      obs = source.multicast(subject)
      obs.connect
      obs
    end

    assert_msgs expected, actual
    assert_msgs expected, subject_obs
    assert_subs source_subs, source
  end

  def test_subject_from_factory
    source      = cold('  -123|')
    expected    = msgs('---123|')
    source_subs = subs('--^---!')

    subject_obs = scheduler.create_observer
    actual = scheduler.configure do
      make_subject = lambda do
        subject = Rx::Subject.new
        subject.subscribe(subject_obs)
        subject
      end
      source.multicast(make_subject)
    end

    assert_msgs expected, actual
    assert_msgs expected, subject_obs
    assert_subs source_subs, source
  end

  def test_factory_raises
    source      = cold('  -1|')
    expected    = msgs('--#')
    source_subs = subs('')

    scheduler.create_observer
    actual = scheduler.configure do
      make_subject = lambda { raise error }
      source.multicast(make_subject)
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_subject_selector
    source      = cold('  -123|')
    expected    = msgs('---234|')
    source_subs = subs('--^---!')

    subject_obs = scheduler.create_observer
    actual = scheduler.configure do
      make_subject = lambda do
        subject = Rx::Subject.new
        subject.subscribe(subject_obs)
        subject
      end
      source.multicast(make_subject, lambda do |connectable|
        connectable.connect
        connectable.map { |n| n + 1 }
      end)
    end

    assert_msgs expected, actual
    assert_msgs msgs('---123|'), subject_obs
    assert_subs source_subs, source
  end

  def test_selector_raises
    source      = cold(' -1|')
    expected    = msgs('--#')
    source_subs = subs('')

    subject_obs = scheduler.create_observer
    actual = scheduler.configure do
      make_subject = lambda do
        subject = Rx::Subject.new
        subject.subscribe(subject_obs)
        subject
      end
      source.multicast(make_subject, lambda { |*_| raise error })
    end

    assert_msgs expected, actual
    assert_msgs [], subject_obs
    assert_subs source_subs, source
  end

  def test_refuse_simple_subject_with_selector
    source = cold(' -1|')
    subject = Rx::Subject.new
    assert_raises(ArgumentError) do
      source.multicast(subject, lambda { |*_| })
    end
  end
end
