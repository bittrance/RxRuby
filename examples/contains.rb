require 'rx'

#  Without an index
source = Rx::Observable.of(42)
  .contains?(42)

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

# => Next: true
# => Completed

