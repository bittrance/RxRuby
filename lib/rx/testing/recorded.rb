# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

module Rx

  # Record of a value including the virtual time it was produced on.
  class Recorded < Struct.new(:time, :value) ; end
end
