module Rx
  class TestTime < Time
    include Comparable

    attr_reader :ts

    def initialize(ts)
      super()
      @ts = ts
    end

    def <=>(other)
      if other.is_a? TestTime
        @ts <=> other.ts
      else
        @ts <=> other
      end
    end

    def +(other)
      TestTime.new(other + @ts)
    end

    def -(other)
      TestTime.new(other - @ts)
    end

    def to_s
      "TestTime @ #{@ts.to_s}"
    end

    def inspect
      "TestTime @ #{@ts.to_s}"
    end
  end
end
