require 'test_helper'

class TestCreationOfEnumerable < Minitest::Test
  include Rx::ReactiveTest

  def test_of_enumerable_empty
    scheduler = Rx::TestScheduler.new

    res = scheduler.configure do
      Rx::Observable.of_enumerable([], scheduler)
    end

    msgs = [
        on_completed(201)
    ]
    assert_messages msgs, res.messages
  end

  def test_of_enumerable_simple
    scheduler = Rx::TestScheduler.new

    res = scheduler.configure do
      Rx::Observable.of_enumerable(%w(foo bar baz), scheduler)
    end

    msgs = [
        on_next(201, 'foo'),
        on_next(202, 'bar'),
        on_next(203, 'baz'),
        on_completed(204)
    ]
    assert_messages msgs, res.messages
  end
end

class TestCreationOfEnumerator < Minitest::Test
  include Rx::ReactiveTest

  def test_of_enumerator_empty
    scheduler = Rx::TestScheduler.new

    res = scheduler.configure do
      Rx::Observable.of_enumerator([].to_enum, scheduler)
    end

    msgs = [
        on_completed(201)
    ]
    assert_messages msgs, res.messages
  end

  def test_of_enumerator_error
    scheduler = Rx::TestScheduler.new
    err = RuntimeError.new
    fibs = Enumerator.new do |x|
      a = b = 1
      6.times do
        x << a
        a, b = b, a + b
      end
      raise err
    end
    res = scheduler.configure do
      Rx::Observable.of_enumerator(fibs, scheduler)
    end

    msgs = [
        on_next(201, 1),
        on_next(202, 1),
        on_next(203, 2),
        on_next(204, 3),
        on_next(205, 5),
        on_next(206, 8),
        on_error(207, err)
    ]
    assert_messages msgs, res.messages
  end

  def test_of_enumerator_infinite_dispose
    scheduler = Rx::TestScheduler.new

    res = scheduler.configure(:disposed => 205) do
      Rx::Observable.of_enumerator([42].cycle, scheduler)
    end

    msgs = [
        on_next(201, 42),
        on_next(202, 42),
        on_next(203, 42),
        on_next(204, 42)
    ]
    assert_messages msgs, res.messages
  end
end