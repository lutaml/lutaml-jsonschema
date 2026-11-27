# frozen_string_literal: true

require_relative "lib/lutaml/jsonschema/version"

Gem::Specification.new do |spec|
  spec.name = "lutaml-jsonschema"
  spec.version = Lutaml::Jsonschema::VERSION
  spec.authors = ["Ribose Inc."]
  spec.email = ["open.source@ribose.com"]

  spec.summary = "JSON Schema model representation and SPA documentation generator"
  spec.description = "Parse JSON Schema files into LutaML model objects and generate SPA documentation sites"
  spec.homepage = "https://github.com/lutaml/lutaml-jsonschema"
  spec.required_ruby_version = ">= 3.2.0"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.license = "BSD-2-Clause"

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__,
                                             err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ .github/
                          .rubocop.yml])
    end
  end.concat(Dir.glob("frontend/dist/*"))
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "json"
  spec.add_dependency "json_schemer", "~> 2.5"
  # Floor the hub at 0.11.9: lutaml 0.11.4-7 depend on lutaml-lml while
  # lutaml-lml needs lutaml >= 0.11.8, so any resolution slipping below
  # 0.11.8 cycles; 0.11.8 is clean but 0.11.9 is the line shipped against
  spec.add_dependency "lutaml", "~> 0.11.9"
  spec.add_dependency "lutaml-model", "~> 0.8.185"
  spec.add_dependency "lutaml-store", "~> 0.3"
  # the XSD export builds through moxml (the org XML abstraction;
  # prefers the leptris engine at runtime) — rexml is retired from the
  # metanorma stack and this was its only in-stack dependent
  spec.add_dependency "moxml", "~> 0.6.20"
  spec.add_dependency "thor", "~> 1.3"
  spec.add_dependency "yeptris", "~> 0.6.86"
end
