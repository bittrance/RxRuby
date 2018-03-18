# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'thread'
require 'rx/core/scheduled_observer'

module Rx

  module Observer
    # Schedules the invocation of observer methods on the given scheduler.
    def notify_on(scheduler)
      ScheduledObserver.new(scheduler, self)
    end
  end
end
