module Rx
  module Observable
    def group_by(key_selector, value_selector, duration_selector)
      AnonymousObservable.new do |observer|
        gate = Mutex.new
        group_map = {}
        group = CompositeSubscription.new
        new_obs = Observer.configure do |o|
          o.on_next do |v|
            key = nil
            value = nil
            begin
              key = key_selector.call(v)
              value = value_selector.call(v)
            rescue => err
              observer.on_error(err)
              group_map.each { |k, s| s.on_error(err) }
              next
            end
            subject = group_map[key]
            unless subject
              subject = group_map[key] = Subject.new
              observer.on_next(subject)
              is = nil
              duration_obs = Observer.configure do |io|
                io.on_error do |err|
                  group_map.delete(key)
                  subject.on_error(err)
                  group.delete(is)
                end
                io.on_completed do
                  group_map.delete(key)
                  subject.on_completed
                  group.delete(is)
                end
              end
              begin
                is = duration_selector.call(subject)
                  .subscribe(duration_obs)
              rescue => err
                group_map.each { |k, s| s.on_error(err) }
                observer.on_error(err)
                next
              end
              group << is
            end
            subject.on_next(value)
          end
          o.on_error do |err|
            group_map.each { |k, s| s.on_error(err) }
            observer.on_error(err)
          end
          o.on_completed do
            group_map.each { |k, s| s.on_completed }
            observer.on_completed
          end
        end
        group << subscribe(new_obs)
      end
    end
  end
end