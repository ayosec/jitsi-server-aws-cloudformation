LIBS = FileList["lib/*.rb"]
SOURCE = "Template.rb"
OUTPUT = "target/template.json"

TARGETDIR = File.dirname(OUTPUT)
directory TARGETDIR

file OUTPUT => [ TARGETDIR, SOURCE ] + LIBS do
  sh "cfndsl", SOURCE, out: OUTPUT
end

desc "Build the template."
task :build => OUTPUT

task :default => :build

namespace :cf do
  desc "Update the stack"
  task :update do
    ruby "scripts/update-stack"
  end

  desc "Show an example file for params.yaml"
  task :params => :build do
    require "json"
    params = JSON.parse(File.read(OUTPUT))["Parameters"]
    params.each_pair do |name, param|
      puts "# #{param["Description"]} (#{param["Type"]})"
      print "# " if name == "IPForSSH"
      puts "#{name}: \"#{param["Default"]}\""
      puts
    end
  end
end
