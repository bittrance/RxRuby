require 'rx'

# This uses and only then source
should_run = true

source = Rx::Observable.if(
    lambda { puts 'Condition'; return should_run },
    Rx::Observable.return(42)
)

puts 'Before'

subscription = source.subscribe(
    lambda {|x|
        puts 'Next: ' + x.to_s
    },
    lambda {|err|
        puts 'Error: ' + err.to_s
    },
    lambda {
        puts 'Completed'
    })

# => Before
# => Condition
# => Next: 42
# => Completed

# The next example uses an elseSource
should_run = false

source = Rx::Observable.if(
    lambda { puts 'Condition'; return should_run },
    Rx::Observable.return(42),
    Rx::Observable.return(56)
)

puts 'Before'

subscription = source.subscribe(
    lambda {|x|
        puts 'Next: ' + x.to_s
    },
    lambda {|err|
        puts 'Error: ' + err.to_s
    },
    lambda {
        puts 'Completed'
    })

# => Before
# => Condition
# => Next: 56
# => Completed
