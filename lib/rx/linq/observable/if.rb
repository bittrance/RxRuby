module Rx
  class << Observable
    def if(condition, then_source, else_source = Observable.empty)
      defer do
        condition.call ? then_source : else_source
      end
    end
  end
end
