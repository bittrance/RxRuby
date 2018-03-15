module Rx
  class << Observable
    def fork_join(*all_sources)
      AnonymousObservable.new {|subscriber|
        count = all_sources.length
        if count == 0
          subscriber.on_completed
          Subscription.empty
        end
        group = CompositeSubscription.new
        finished = false
        has_results = Array.new(count)
        has_completed  = Array.new(count)
        results  = Array.new(count)

        count.times {|i|
          source = all_sources[i]
          group.push(
            source.subscribe(
              lambda {|value|
                if !finished
                  has_results[i] = true
                  results[i] = value
                end
              },
              lambda {|e|
                finished = true
                subscriber.on_error e
                group.unsubscribe
              },
              lambda {
                if !finished
                  if has_results[i]
                    has_completed[i] = true
                    unless has_completed.include?(nil)
                      finished = true
                      subscriber.on_next results
                      subscriber.on_completed
                    end
                  else
                    subscriber.on_completed
                  end
                end
              }
            )
          )
        }
        group
      }
    end
  end
end
