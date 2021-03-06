require 'rx/testing/reactive_test'

module Rx
  module MarbleTesting
    include Rx::ReactiveTest

    class MyError < RuntimeError ; end

    def error
      @err ||= MyError.new
    end

    def msgs(events, values = {})
      time = 0
      increment = 100
      events.chars.map do |event|
        message = case event
        when ' '
          next
        when '-'
          nil
        when '('
          increment = 0
          nil
        when ')'
          increment = 100
          nil
        when '|'
          on_completed(time)
        when '#'
          v = values[:error] || error
          if v.is_a? Proc
            on_error_predicate(time, &v)
          else
            on_error(time, v)
          end
        else
          v = values.fetch(event.to_sym, (Integer(event) rescue event))
          if v.is_a? Proc
            on_next_predicate(time, &v)
          else
            on_next(time, v)
          end
        end
        time += increment
        message
      end.compact
    end

    def subs(events)
      time = 0
      increment = 100
      subscribe_time = nil
      result = events.chars.map do |event|
        sub = case event
        when ' ', '-'
          nil
        when '('
          increment = 0
          nil
        when ')'
          increment = 100
          nil
        when '^'
          subscribe_time = time
          nil
        when '!'
          st, subscribe_time = subscribe_time, nil
          subscribe(st, time)
        end
        time += increment
        sub
      end.compact
      if subscribe_time
        result << subscribe(subscribe_time, nil)
      end
      result
    end

    def assert_subs(expected, actual)
      assert_subscriptions expected, actual.subscriptions
    end

    def assert_msgs(expected, actual)
      assert_messages expected, actual.messages
    end

    def cold(events, values = {})
      messages = msgs(events, values)
      scheduler.create_cold_observable(*messages)
    end

    def hot(events, values = {})
      messages = msgs(events, values)
      scheduler.create_hot_observable(*messages)
    end
  end
end
