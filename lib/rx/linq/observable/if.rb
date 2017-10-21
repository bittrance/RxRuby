module Rx
  class << Observable
    def if(condition, then_source, else_source_or_scheduler = nil)
      defer do
        if else_source_or_scheduler.respond_to?(:subscribe)
          else_source = else_source_or_scheduler
        elsif else_source_or_scheduler.nil?
          else_source = Observable.empty
        else
          scheduler = else_source_or_scheduler
          else_source = Observable.empty(scheduler)
        end

        condition.call ? then_source : else_source
      end
    end
  end
end
