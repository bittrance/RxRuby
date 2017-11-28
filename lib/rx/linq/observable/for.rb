module Rx
  class << Observable
    def for(sources, &transform)
      raise ArgumentError.new 'sources must be enumerable' unless sources.respond_to? :each
      enum = if block_given?
        ThreadedEnumerator.new {|y|
          sources.each {|v| y << yield(v) }
        }
      else
        ThreadedEnumerator.new(sources)
      end
      Observable.concat(enum)
    end
  end
end
