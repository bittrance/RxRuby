require 'test_helper'

class TestCreationCreate < Minitest::Test
  include Rx::MarbleTesting

def test_create_completed
    res = scheduler.configure do
      Rx::Observable.create do |obs|
        obs.on_completed
        obs.on_next 100
        obs.on_error RuntimeError.new
        obs.on_completed
        nil
      end
    end
    
    assert_messages [on_completed(200)], res.messages    
  end

  def test_create_error
    err = RuntimeError.new
    scheduler = Rx::TestScheduler.new

    res = scheduler.configure do 
      Rx::Observable.create do |obs|
        obs.on_error err
        obs.on_next 100
        obs.on_error RuntimeError.new
        obs.on_completed
        nil
      end
    end
    
    assert_messages [on_error(200, err)], res.messages     
  end

  def test_create_unsubscribe
    scheduler = Rx::TestScheduler.new

    res = scheduler.configure do 
      Rx::Observable.create do |obs|
        stopped = false
        
        obs.on_next 1
        obs.on_next 2

        scheduler.schedule_relative(600, lambda {
          obs.on_next 3 unless stopped  
        })

        scheduler.schedule_relative(700, lambda {
          obs.on_next 4 unless stopped  
        })  

        scheduler.schedule_relative(900, lambda {
          obs.on_next 5 unless stopped  
        })

        scheduler.schedule_relative(1100, lambda {
          obs.on_next 6 unless stopped  
        })                

        Rx::Subscription.create { stopped = true }
      end
    end
    
    msgs = [
      on_next(200, 1),
      on_next(200, 2),
      on_next(800, 3),
      on_next(900, 4)
    ]
    assert_messages msgs, res.messages      
  end

  def test_create_observer_raises
    assert_raises(RuntimeError) do 

      observable = Rx::Observable.create do |obs|
        obs.on_next 1
        nil
      end

      observer = Rx::Observer.configure do |o|
        o.on_next {|x| raise RuntimeError.new }
      end

      observable.subscribe observer
    end

    assert_raises(RuntimeError) do 

      observable = Rx::Observable.create do |obs|
        obs.on_error RuntimeError.new
        nil
      end

      observer = Rx::Observer.configure do |o|
        o.on_error {|err| raise RuntimeError.new }
      end

      observable.subscribe observer
    end

    assert_raises(RuntimeError) do 

      observable = Rx::Observable.create do |obs|
        obs.on_completed
        nil
      end

      observer = Rx::Observer.configure do |o|
        o.on_completed { raise RuntimeError.new }
      end

      observable.subscribe observer
    end    
  end

  def test_create_next_return_subscription
    actual = scheduler.configure do
      Rx::Observable.create do |obs|
        obs.on_next 1
        obs.on_next 2
        Rx::Subscription.empty
      end
    end

    assert_msgs msgs('--(12)'), actual
  end

  def test_create_next_return_nil
    actual = scheduler.configure do
      Rx::Observable.create do |obs|
        obs.on_next 1
        obs.on_next 2
        nil
      end
    end

    assert_msgs msgs('--(12)'), actual
  end

  def test_create_with_unsubscribe_action
    disposed = false
    scheduler.configure do
      Rx::Observable.create do |obs|
        lambda { disposed = scheduler.now }
      end
    end
    assert_equal 1000, disposed
  end
end
