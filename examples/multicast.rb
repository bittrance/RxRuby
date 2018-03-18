require 'rx'

subject = Rx::Subject.new
source = Rx::Observable.range(0, 3)
    .multicast(subject)

observer = Rx::Observer.configure do |o|
  o.on_next {|x| puts 'Next: ' + x.to_s }
  o.on_error {|err| puts 'Error: ' + err.to_s }
  o.on_completed { puts 'Completed' }
end

subscription = source.subscribe(observer)
subject.subscribe(observer)

connected = source.connect

subscription.dispose

# => Next: 0
# => Next: 0
# => Next: 1
# => Next: 1
# => Next: 2
# => Next: 2
# => Completed
