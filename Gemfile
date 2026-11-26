# frozen_string_literal: true

source "https://rubygems.org"

gemspec

gem "canon", "~> 0.2"
# the CDDL exporter's specs parse the generated rules back with the
# RFC 8610 reference parser
gem "cddl", "~> 0.12"
gem "irb"
# Ruby 4.0 moved pstore out of the default gems; the cddl chain
# (regexp-examples) loads it
gem "pstore"
gem "rake", "~> 13.0"
# Ruby 4.0 moved benchmark out of the default gems; the perf harness needs it
gem "benchmark"
gem "rspec", "~> 3.0"
gem "rubocop", "~> 1.21"
gem "rubocop-performance", "~> 1.0"
