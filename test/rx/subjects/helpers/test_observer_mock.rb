class TestObserverMock
  include Rx::Observer
  attr_reader :next, :error, :completed
  def initialize
    @next = []
    @error = false
    @completed = false
  end

  def on_next(value)
    @next << value
  end

  def on_error(error)
    @error = error
  end

  def on_completed
    @completed = true
  end
end
