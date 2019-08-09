lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name    = "fluent-plugin-port-to-service"
  spec.version = "0.0.9"
  spec.authors = ["Chris Pedro"]
  spec.email   = ["chris@thepedros.com"]

  spec.summary       = %q{Filter Fluentd to include TCP/UDP services.}
  spec.description   = %q{Filter Fluentd to include TCP/UDP services.}
  spec.homepage      = "https://github.com/cpedro/fluent-plugin-port-to-service.git"
  spec.license       = "Unlicense"

  test_files, files  = `git ls-files -z`.split("\x0").partition do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.files         = files
  spec.executables   = files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = test_files
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "> 1.14"
  spec.add_development_dependency "rake", "> 12.0"
  spec.add_development_dependency "test-unit", "> 3.0"
  spec.add_runtime_dependency "fluentd", [">= 0.14.10", "< 2"]
  spec.add_runtime_dependency "sqlite3", ">= 1.3.7"
end
