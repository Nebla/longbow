require "bundler/gem_tasks"

gemspec = eval(File.read("longbow-fdv.gemspec"))

task :build => "#{gemspec.full_name}.gem"

file "#{gemspec.full_name}.gem" => gemspec.files + ["longbow-fdv.gemspec"] do
  system "gem build longbow-fdv.gemspec"
end