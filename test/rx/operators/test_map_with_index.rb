require 'test_helper'

class TestOperatorMap < Minitest::Test
  include Rx::MarbleTesting

  def test_replaces_value_with_block_result
    source      = cold('  -123|')
    expected    = msgs('---234|')
    source_subs = subs('  ^   !')

    actual = scheduler.configure do
      source.map { |x| x + 1 }
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
  end
end

class TestOperatorMapWithIndex < Minitest::Test
  include Rx::MarbleTesting

  def test_replaces_value_with_block_result
    source      = cold('  -123|')
    expected    = msgs('---abc|', a: [0, 2], b: [1, 3], c: [2, 4])
    source_subs = subs('  ^   !')

    actual = scheduler.configure do
      source.map_with_index { |x, i| [i, x + 1] }
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_respects_nil_as_value
    source      = cold('  -a|', a: nil)
    expected    = msgs('---a|', a: nil)
    source_subs = subs('  ^ !')

    actual = scheduler.configure do
      source.map_with_index { |x, _| x }
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_erroring_block
    source      = cold('  -1')
    expected    = msgs('---#')
    source_subs = subs('  ^!')

    actual = scheduler.configure do
      source.map_with_index { raise error }
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_propagates_error
    source      = cold('  -#')
    expected    = msgs('---#')
    source_subs = subs('  ^!')

    actual = scheduler.configure do
      source.map_with_index { |x, i| [i, x] }
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
  end
end

class TestOperatorFlatMap < Minitest::Test
  include Rx::MarbleTesting

  def test_flattens_output_from_block
    a           = cold('   1-3|')
    b           = cold('    2-4--|')
    c           = cold('     --5|')
    source      = cold('  -abc|')
    expected    = msgs('---12345-|')
    source_subs = subs('  ^   !')
    a_subs      = subs('   ^  !')
    b_subs      = subs('    ^    !')
    c_subs      = subs('     ^  !')

    actual = scheduler.configure do
      source.flat_map do |x|
        {'a' => a, 'b' => b, 'c' => c}.fetch(x)
      end
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
    assert_subs a_subs, a
    assert_subs b_subs, b
    assert_subs c_subs, c
  end
end

class TestOperatorFlatMapWithIndex < Minitest::Test
  include Rx::MarbleTesting

  def test_flattens_output_from_indexing_block
    source      = cold('  -12345|')
    expected    = msgs('---13579|')
    source_subs = subs('  ^     !')

    actual = scheduler.configure do
      source.flat_map_with_index do |x, i|
        Rx::Observable.just(x + i)
      end
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
  end
end
