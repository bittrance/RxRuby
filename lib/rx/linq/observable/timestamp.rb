module Rx
  Timestamp = Struct.new(:timestamp, :value)

  module Observable
    def timestamp(scheduler = DefaultScheduler.instance)
      map do |x|
        Timestamp.new(scheduler.now, x)
      end
    end
  end
end
