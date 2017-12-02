if ENV['COVERAGE']
  require 'simplecov'

  SimpleCov.start do
    coverage_dir '.coverage'
    add_filter do |f|
      !%r{/lib/rx}.match(f.filename)
    end  end
end

require 'minitest/autorun'
require 'rx'
