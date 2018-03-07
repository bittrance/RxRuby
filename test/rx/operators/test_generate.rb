require 'test_helper'

class TestCreationGenerate < Minitest::Test
  include Rx::ReactiveTest

  def test_generate_finite
    scheduler = Rx::TestScheduler.new

    res = scheduler.configure do
      Rx::Observable.generate(
        0,
        lambda { |x| return x <= 3 },
        lambda { |x| return x + 1 },
        lambda { |x| return x },
        scheduler)
    end

    msgs = [
      on_next(201, 0),
      on_next(202, 1),
      on_next(203, 2),
      on_next(204, 3),
      on_completed(205)      
    ]
    assert_messages msgs, res.messages
  end

  def test_generate_condition_raise
    scheduler = Rx::TestScheduler.new
    err = RuntimeError.new

    res = scheduler.configure do
      Rx::Observable.generate(
        0,
        lambda { |x| raise err },
        lambda { |x| return x + 1 },
        lambda { |x| return x },
        scheduler)
    end

    msgs = [
      on_error(201, err)  
    ]
    assert_messages msgs, res.messages
  end

  def test_generate_raise_result_selector
    scheduler = Rx::TestScheduler.new
    err = RuntimeError.new

    res = scheduler.configure do
      Rx::Observable.generate(
        0,
        lambda { |x| return true },
        lambda { |x| return x + 1 },
        lambda { |x| raise err },
        scheduler)
    end

    msgs = [
      on_error(201, err)  
    ]
    assert_messages msgs, res.messages    
  end

  def test_generate_raise_iterate
    scheduler = Rx::TestScheduler.new
    err = RuntimeError.new

    res = scheduler.configure do
      Rx::Observable.generate(
        0,
        lambda { |x| return true },
        lambda { |x| raise err },
        lambda { |x| return x },
        scheduler)
    end

    msgs = [
      on_next(201, 0),
      on_error(202, err)
    ]
    assert_messages msgs, res.messages    
  end

  def test_generate_dispose
    scheduler = Rx::TestScheduler.new

    res = scheduler.configure(:disposed => 203) do
      Rx::Observable.generate(
        0,
        lambda { |x| return x <= 3 },
        lambda { |x| return x + 1 },
        lambda { |x| return x },
        scheduler)
    end

    msgs = [
      on_next(201, 0),
      on_next(202, 1),     
    ]
    assert_messages msgs, res.messages
  end
end