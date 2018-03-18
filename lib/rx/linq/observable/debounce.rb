module Rx
  module Observable
    def debounce(due_time, scheduler = DefaultScheduler.instance)
      raise ArgumentError.new('due_time must be at least zero') if due_time < 0
      AnonymousObservable.new do |observer|
        cancelable = SerialSubscription.new
        hasvalue = false
        value = nil
        id = 0

        subscription = subscribe(
          lambda {|x|
            hasvalue = true
            value = x
            id += 1
            current_id = id
            d = SingleAssignmentSubscription.new
            cancelable.subscription = d
            d.subscription = scheduler.schedule_relative(due_time, lambda {
              observer.on_next value if hasvalue && id == current_id
              hasvalue = false
            })
          },
          lambda {|e|
            cancelable.unsubscribe
            observer.on_error e
            hasvalue = false
            id += 1
          },
          lambda {
            cancelable.unsubscribe
            observer.on_next value if hasvalue
            observer.on_completed
            hasvalue = false
            id += 1
          })

        CompositeSubscription.new [subscription, cancelable]
      end
    end
  end
end
