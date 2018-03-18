require 'rx'

subscription = Rx::Subscription.create {
    puts 'disposed'
}

subscription.unsubscribe
# => disposed

subscription = Rx::Subscription.empty

subscription.unsubscribe # Does nothing
