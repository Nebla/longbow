require "bundler/gem_tasks"

gemspec = eval(File.read("distll-app-generator.gemspec"))

task :build => "#{gemspec.full_name}.gem"

file "#{gemspec.full_name}.gem" => gemspec.files + ["distll-app-generator.gemspec"] do
  system "gem build distll-app-generator.gemspec"
end