if ENV['CODECOV_TOKEN']
  require 'simplecov'
  require 'codecov'

  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::Codecov
  ])
  SimpleCov.start do
    coverage_dir '.coverage'
    add_filter do |f|
      !%r{/lib/rx}.match(f.filename)
    end  end
end

require 'minitest/autorun'
require 'rx'
