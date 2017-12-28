require 'test_helper'

class TestOperatorScan < Minitest::Test
  include Rx::MarbleTesting

  class Reducable
    attr_reader :value

    def initialize(value)
      @value = value
    end

    def reduce(other)
      Reducable.new(value + other.value)
    end

    def ==(other)
      value == other.value
    end
  end

  def test_symbol_names_reducer_on_emitted_value
    source       = cold('  -ab|', a: Reducable.new(1), b: Reducable.new(2))
    expected     = msgs('---ab|', a: Reducable.new(1), b: Reducable.new(3))
    source_subs  = subs('  ^  !')

    actual = scheduler.configure { source.scan(:reduce) }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_seed_reducer_named_by_symbol
    source       = cold('  -ab|', a: Reducable.new(1), b: Reducable.new(2))
    expected     = msgs('---ab|', a: Reducable.new(2), b: Reducable.new(4))
    source_subs  = subs('  ^  !')

    actual = scheduler.configure { source.scan(Reducable.new(1), :reduce) }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_scan_emitted_values_using_block
    source       = cold('  -12|')
    expected     = msgs('---13|')
    source_subs  = subs('  ^  !')

    actual = scheduler.configure do
      source.scan { |acc, x| acc + x }
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_seed_scan_with_block
    source       = cold('  -12|')
    expected     = msgs('---24|')
    source_subs  = subs('  ^  !')

    actual = scheduler.configure do
      source.scan(1) { |acc, x| acc + x }
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_with_error
    source       = cold('  -12#')
    expected     = msgs('---13#')
    source_subs  = subs('  ^  !')

    actual = scheduler.configure do
      source.scan { |acc, x| acc + x }
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_erroring_block
    source       = cold('  -12')
    expected     = msgs('---1#')
    source_subs  = subs('  ^ !')

    actual = scheduler.configure do
      source.scan { |acc, x| raise error }
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_erroring_block_with_seed
    source       = cold('  -2')
    expected     = msgs('---#')
    source_subs  = subs('  ^!')

    actual = scheduler.configure do
      source.scan(1) { |acc, x| raise error }
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_empty_observable
    source       = cold('  -|')
    expected     = msgs('---|')
    source_subs  = subs('  ^!')

    actual = scheduler.configure do
      source.scan { |acc, x| acc + x }
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_empty_observable_with_seed
    source       = cold('  -|')
    expected     = msgs('---(1|)')
    source_subs  = subs('  ^!')

    actual = scheduler.configure do
      source.scan(1) { |acc, x| acc + x }
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_argument_error_on_too_many_arguments
    source = cold('  -1')
    assert_raises(ArgumentError) do
      source.scan(1, 2) { |_| }
    end
  end
end
