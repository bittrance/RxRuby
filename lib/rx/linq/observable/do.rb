module Rx
  module Observable
    # Invokes the observer's methods for each message in the source sequence.
    # This method can be used for debugging, logging, etc. of query behavior by intercepting the message stream to run arbitrary actions for messages on the pipeline.
    def do(observer_or_on_next = nil, on_error_func = nil, on_completed_func = nil)
      if block_given?
        on_next_func = Proc.new
      elsif Proc === observer_or_on_next
        on_next_func = observer_or_on_next
      else
        on_next_func = observer_or_on_next.method(:on_next)
        on_error_func = observer_or_on_next.method(:on_error)
        on_completed_func = observer_or_on_next.method(:on_completed)
      end
      AnonymousObservable.new do |observer|
        subscribe(
          lambda {|x|
            begin
              on_next_func.call x
            rescue => e
              observer.on_error e
            end
            observer.on_next x
          },
          lambda {|err|
            begin
              on_error_func && on_error_func.call(err)
            rescue => e
              observer.on_error e
            end
            observer.on_error err
          },
          lambda {
            begin
              on_completed_func && on_completed_func.call
            rescue => e
              observer.on_error e
            end
            observer.on_completed
          })
      end
    end
  end
end
