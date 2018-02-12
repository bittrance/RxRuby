module Rx
  class << Observable
    def timer(due_time, period_or_scheduler = DefaultScheduler.instance, scheduler = DefaultScheduler.instance)
      case period_or_scheduler
      when Numeric
        period = period_or_scheduler
      when Scheduler
        scheduler = period_or_scheduler
      end

      if Time === due_time
        if period.nil?
          AnonymousObservable.new do |observer|
            scheduler.schedule_absolute(due_time,
              lambda {
                observer.on_next(0)
                observer.on_completed
              })
          end
        else
          AnonymousObservable.new do |observer|
            count = 0
            d = due_time
            p = Scheduler.normalize(period)
            scheduler.schedule_recursive_absolute(d, lambda {|this|
              if p > 0
                now = scheduler.now()
                d = d + p
                d <= now && (d = now + p)
              end
              observer.on_next(count)
              count += 1
              this.call(d)
            })
          end
        end
      else
        if period.nil?
          AnonymousObservable.new do |observer|
            scheduler.schedule_relative(Scheduler.normalize(due_time),
              lambda {
                observer.on_next(0)
                observer.on_completed
              })
          end
        else
          AnonymousObservable.new do |observer|
            count = 0
            scheduler.schedule_recursive_relative(due_time, lambda { |this|
              observer.on_next(count)
              count += 1
              this.call(period)
            })
          end
        end
      end
    end
  end
end
