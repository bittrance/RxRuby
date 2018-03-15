require 'test_helper'

class TestCreationUsing < Minitest::Test
  include Rx::MarbleTesting

  class Resource
    attr_reader :unsubscribed, :messages

    def initialize(messages)
      @messages = messages
    end

    def unsubscribe
      @unsubscribed = true
    end
  end

  def test_resource_used_for_observable_factory
    resource = Resource.new('123|')

    actual = scheduler.configure do
      Rx::Observable.using(
        lambda { resource },
        lambda { |r| cold(r.messages) }
      )
    end

    assert_msgs msgs('--123|'), actual
    assert resource.unsubscribed
  end

  def test_resource_unsubscribed_on_completion
    resource = Resource.new('--|')

    Rx::Observable.using(
      lambda { resource },
      lambda { |r| cold(r.messages) }
    ).subscribe(scheduler.create_observer)

    scheduler.advance_to(100)
    refute resource.unsubscribed
    scheduler.advance_to(200)
    assert resource.unsubscribed
  end

  def test_resource_factory_error
    actual = scheduler.configure do
      Rx::Observable.using(
        lambda { raise error },
        lambda { |r| cold(r.messages) }
      )
    end

    assert_msgs msgs('--#'), actual
  end

  def test_observable_factory_error
    resource = Resource.new('123|')

    actual = scheduler.configure do
      Rx::Observable.using(
        lambda { resource },
        lambda { |r| raise error }
      )
    end

    assert_msgs msgs('--#'), actual
    assert resource.unsubscribed
  end
end
