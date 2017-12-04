# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

module Rx

  # Records information about subscriptions to and unsubscriptions from observable sequences.
  TestSubscription = Struct.new(:subscribe, :unsubscribe)
end
