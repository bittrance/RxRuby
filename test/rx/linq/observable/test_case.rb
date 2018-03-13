require 'test_helper'

class TestOperatorCase < Minitest::Test
  include Rx::MarbleTesting

  def test_select_from_array_of_sources
    sources = [cold('-0|'), cold('-1|')]
    expected = msgs('---1|')

    actual = scheduler.configure do
      Rx::Observable.case(lambda { 1 }, sources, scheduler)
    end

    assert_msgs expected, actual
  end

  def test_select_from_hash_of_sources
    sources = {a: cold('-a|'), b: cold('-b|')}
    expected = msgs('---b|')

    actual = scheduler.configure do
      Rx::Observable.case(lambda { :b }, sources, scheduler)
    end

    assert_msgs expected, actual
  end

  def test_complete_on_lookup_failure
    sources = {}
    expected = msgs('--|')

    actual = scheduler.configure do
      Rx::Observable.case(lambda { :b }, sources, scheduler)
    end

    assert_msgs expected, actual
  end

  def test_propagate_selector_error
    expected = msgs('--#')

    actual = scheduler.configure do
      Rx::Observable.case(lambda { raise error }, [], scheduler)
    end

    assert_msgs expected, actual
  end

  def test_propagate_error
    sources = [cold('-#|')]
    expected = msgs('---#')

    actual = scheduler.configure do
      Rx::Observable.case(lambda { 0 }, sources, scheduler)
    end

    assert_msgs expected, actual
  end
end