require 'test_helper'

class TestOperatorReduce < Minitest::Test
  include Rx::MarbleTesting
  
  class Reducable
    attr_reader :value

    def initialize(value)
      @value = value
    end

    def reduce_me(other)
      Reducable.new(value + other.value)
    end

    def ==(other)
      value == other.value
    end
  end
  
  def test_symbol_names_reducer_on_emitted_value
    left       = cold('  -ab|', a: Reducable.new(1), b: Reducable.new(2))
    expected   = msgs('-----(a|)', a: Reducable.new(3))
    left_subs  = subs('  ^  !')

    actual = scheduler.configure { left.reduce(:reduce_me) }

    assert_msgs expected, actual
    assert_subs left_subs, left
  end

  def test_seed_reducer_named_by_symbol
    left       = cold('  -ab|', a: Reducable.new(1), b: Reducable.new(2))
    expected   = msgs('-----(a|)', a: Reducable.new(4))
    left_subs  = subs('  ^  !')

    actual = scheduler.configure { left.reduce(Reducable.new(1), :reduce_me) }

    assert_msgs expected, actual
    assert_subs left_subs, left
  end

  def test_reduce_emitted_values_using_block
    left       = cold('  -12|')
    expected   = msgs('-----(3|)')
    left_subs  = subs('  ^  !')

    actual = scheduler.configure do
      left.reduce { |acc, x| acc + x }
    end

    assert_msgs expected, actual
    assert_subs left_subs, left
  end

  def test_seed_reducer_using_block
    left       = cold('  -12|')
    expected   = msgs('-----(4|)')
    left_subs  = subs('  ^  !')

    actual = scheduler.configure do
      left.reduce(1) { |acc, x| acc + x }
    end

    assert_msgs expected, actual
    assert_subs left_subs, left
  end

  def test_with_error
    left       = cold('  -12#')
    expected   = msgs('-----#')
    left_subs  = subs('  ^  !')

    actual = scheduler.configure do
      left.reduce { |acc, x| acc + x }
    end

    assert_msgs expected, actual
    assert_subs left_subs, left
  end

  def test_erroring_block
    left       = cold('  -12')
    expected   = msgs('----#')
    left_subs  = subs('  ^ !')

    actual = scheduler.configure do
      left.reduce { |acc, x| raise error }
    end

    assert_msgs expected, actual
    assert_subs left_subs, left
  end

  def test_erroring_block_with_seed
    left       = cold('  -2')
    expected   = msgs('---#')
    left_subs  = subs('  ^!')

    actual = scheduler.configure do
      left.reduce(1) { |acc, x| raise error }
    end

    assert_msgs expected, actual
    assert_subs left_subs, left
  end

  def test_emits_error_on_empty_sequence
    my_err = ->(err) { err.is_a?(RuntimeError) && err.message.include?('no elements') }

    left       = cold('  -|')
    expected   = msgs('---#', error: my_err)
    left_subs  = subs('  ^!')

    actual = scheduler.configure do
      left.reduce { |acc, x| acc + x }
    end

    assert_msgs expected, actual
    assert_subs left_subs, left
  end

  def test_seed_emitted_even_on_empty_sequence
    left       = cold('  -|')
    expected   = msgs('---(1|)')
    left_subs  = subs('  ^!')

    actual = scheduler.configure do
      left.reduce(1) { |acc, x| acc + x }
    end

    assert_msgs expected, actual
    assert_subs left_subs, left
  end

  def test_too_many_arguments
    left       = cold('  -1')
    assert_raises(ArgumentError) do
      left.reduce(1, 2) { |_| }
    end
  end
end