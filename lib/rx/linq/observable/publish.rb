module Rx
  module Observable
    def publish(&selector)
      if block_given?
        multicast(lambda { Subject.new }, selector)
      else
        multicast(Subject.new)
      end
    end
  end
end
