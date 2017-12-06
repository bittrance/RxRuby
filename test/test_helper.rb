if ENV['COVERAGE']
  require 'coveralls'
  require 'simplecov'

  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
    SimpleCov::Formatter::HTMLFormatter,
    Coveralls::SimpleCov::Formatter
  ]
  SimpleCov.start do
    coverage_dir '.coverage'
    add_filter do |f|
      !%r{/lib/rx}.match(f.filename)
    end  end
end

require 'minitest/autorun'
require 'rx'
