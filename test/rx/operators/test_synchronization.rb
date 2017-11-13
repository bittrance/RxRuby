# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require "#{File.dirname(__FILE__)}/../../test_helper"

class TestObservableSynchronization < Minitest::Test
  include Rx::ReactiveTest

  def test_subscribe_on_default_scheduler_does_not_raise
    Rx::Observable.just(1).subscribe_on(Rx::DefaultScheduler.instance).subscribe
  end

  def test_subscribe_on_current_thread_scheduiler_does_not_raise
    Rx::Observable.just(1).subscribe_on(Rx::CurrentThreadScheduler.instance).subscribe
  end
end
