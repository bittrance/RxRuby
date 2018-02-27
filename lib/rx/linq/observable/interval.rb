module Rx
  class << Observable
    def interval(period, scheduler = Rx::DefaultScheduler.instance)
      self.timer(period, period, scheduler)
    end
  end
end
