# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'test_helper'

class TestSubscription < Minitest::Test

  def test_disposable_create
    d = Rx::Subscription.create { }
    refute_nil d
  end

  def test_create_dispose
    unsubscribed = 0
    d = Rx::Subscription.create { unsubscribed += 1 }
    assert_equal 0, unsubscribed

    d.unsubscribe
    assert_equal 1, unsubscribed
    d.unsubscribe
    assert_equal 1, unsubscribed
  end

  def test_empty
    d = Rx::Subscription.empty
    refute_nil d
    d.unsubscribe
  end

end
