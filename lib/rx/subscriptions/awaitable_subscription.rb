module Rx
  class AwaitableSubscription < SingleAssignmentSubscription
    def initialize
      super
      @completed = false
      @condition = ConditionVariable.new
    end

    def subscription=(new_subscription)
      blocker = Subscription.create do
        @completed = true
        @condition.signal
      end
      super CompositeSubscription.new [new_subscription, blocker]
    end

    def await(timeout)
      raise RuntimeError.new 'Cannot await before subscription' unless subscription
      gate = Mutex.new
      deadline = Time.now + timeout
      until Time.now >= deadline || @completed
        gate.synchronize do
          @condition.wait(gate, deadline - Time.now) unless @completed
        end
      end
      @completed
    end
  end
end