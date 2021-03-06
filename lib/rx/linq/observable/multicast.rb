module Rx
  module Observable
    def multicast(subject_or_subject_selector, selector = nil)
      if Proc === subject_or_subject_selector
        selector ||= lambda { |c| c.connect ; c }
        AnonymousObservable.new do |observer|
          connectable = self.multicast(subject_or_subject_selector.call)
          selector.call(connectable).subscribe(observer)
        end
      else
        unless selector.nil?
          raise ArgumentError, 'When passing single subject, selector is not supported.'
        end
        ConnectableObservable.new(self, subject_or_subject_selector)
      end
    end
  end
end
