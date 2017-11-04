require "#{File.dirname(__FILE__)}/../../test_helper"

class TestStandardQueryOperators < Minitest::Test
  include Rx::ReactiveTest

  def test_select_with_index
    ns = []
    is = []
    Rx::Observable.of(1, 2, 3, 4, 5, 6)
    .select_with_index {|n, i| is << i ; n % 2 == 0 }
    .subscribe {|n| ns << n }
    assert_equal [2, 4, 6], ns
    assert_equal [0, 1, 2, 3, 4, 5], is
  end
  
  def test_reject_with_index
    ns = []
    is = []
    Rx::Observable.of(1, 2, 3, 4, 5, 6)
    .reject_with_index {|n, i| is << i ; n % 2 == 0 }
    .subscribe {|n| ns << n }
    assert_equal [1, 3, 5], ns
    assert_equal [0, 1, 2, 3, 4, 5], is
  end
end