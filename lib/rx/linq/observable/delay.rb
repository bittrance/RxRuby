require 'time'

module Rx
  module Observable
    def delay(due_time, scheduler = DefaultScheduler.instance)
      if Time === due_time
        delay_date(due_time, scheduler)
      elsif DateTime === due_time
        delay_date(due_time.to_time, scheduler)
      else
        raise ArgumentError, 'due_time must be at least 0' if due_time < 0
        delay_time_span(due_time, scheduler)
      end
    end

    private

    def delay_time_span(due_time, scheduler)
      AnonymousObservable.new do |observer|
        gate = Mutex.new
        q = []
        state = :running
        cancelable = SerialSubscription.new
        subscription = nil
        new_obs = Observer.configure do |o|
          o.on_next do |x|
            size = nil
            gate.synchronize do
              size = q.size
              q << [scheduler.now + due_time, x]
            end
            if size == 0 && state == :running
              cancelable.subscription = scheduler.schedule_recursive_relative(due_time,  lambda do |this|
                v = nil
                next_time = nil
                gate.synchronize do
                  _, v = q.shift
                  next_time, _ = q.first
                end
                observer.on_next(v)
                if next_time.nil? && state == :complete
                  observer.on_completed
                elsif !next_time.nil? && state != :dead
                  next_due = next_time - scheduler.now
                  this.call(next_due)
                end
              end)
            end
          end

          o.on_error do |err|
            state = :dead
            cancelable.unsubscribe
            observer.on_error(err)
          end

          o.on_completed do
            state = :complete
            subscription.unsubscribe if subscription
            observer.on_completed if q.size == 0
          end
        end

        subscription = subscribe(new_obs)
        subscription.unsubscribe if state == :complete
        CompositeSubscription.new [subscription, cancelable]
      end
    end

    def delay_date(due_time, scheduler)
      delay_time_span(due_time - scheduler.now, scheduler)
    end
  end
end
