# frozen_string_literal: true

source "https://rubygems.org"

gemspec

gem "canon", "~> 0.2"
# the CDDL exporter's specs parse the generated rules back with the
# RFC 8610 reference parser
gem "cddl", "~> 0.12"
gem "irb"
# the LML exporter's specs parse the generated models back with the
# org's LML toolchain
gem "lutaml-lml", "~> 0.3"
# the lutaml line this bundle resolves (>= 0.11.8) requires the parsanol
# 1.5 line; capping at ~> 1.3 pushes the resolver onto lutaml 0.11.4-7,
# which cycle with lutaml-lml and fail resolution outright
gem "parsanol", "~> 1.5"
# Ruby 4.0 moved pstore out of the default gems; the cddl chain
# (regexp-examples) loads it
gem "pstore"
gem "rake", "~> 13.0"
# Ruby 4.0 moved benchmark out of the default gems; the perf harness needs it
gem "benchmark"
gem "rspec", "~> 3.0"
gem "rubocop", "~> 1.21"
gem "rubocop-performance", "~> 1.0"
