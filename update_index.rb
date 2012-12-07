#!/usr/bin/ruby
# Set up index.html for results directory

require 'fileutils'
INDEX="index.html"

def build_html(title, hash)
  html  = "<h2>#{title}</h2>\n"
  html += "<ul>\n"
  
  hash.each do |key, val|
    html += "<li>#{key}<ul>"
    val.each do |dir|
      html += "<li><a href=\"#{dir}\">#{dir}</a></li>"
    end
    html += "</ul></li>\n"
  end

  html += "</ul>\n"
  return html
end

unless ARGV[0] 
  puts "ERROR: missing parameter"
  puts "usage: DIRECTORY"
  exit 1 
end

path = File.expand_path(ARGV[0])

unless File.directory?(path)
  puts "#{path} is not a directory"
  exit 1
end

Dir.chdir(path)
if File.exist?(INDEX)
  FileUtils.mv(INDEX, INDEX + ".old")
end

html_header = <<-EOD
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
  <head>
    <title>Test Run Index</title>
    <meta http-equiv="content-type" content="text/html; charset=iso-8859-1">
  </style>
</head>
<body>
  <h1>Test Run Index</h1>
EOD

html_footer = <<-EOD
</body>
EOD

configurations = Hash.new
workspaces = Hash.new
tests = Hash.new

Dir.glob("*").each do |dir|
  if File.directory?(dir)
    parts = dir.split("-")
    if parts.size == 5
      puts "Adding #{dir} ..."
      configuration = parts[2]
      workspace = parts[3]
      test = parts[4]

      unless configurations.has_key?(configuration)
        configurations[configuration] = [ ]
      end
      configurations[configuration].push(dir)

      unless workspaces.has_key?(workspace)
        workspaces[workspace] = [ ]
      end
      workspaces[workspace].push(dir)

      unless tests.has_key?(test)
        tests[test] = [ ]
      end
      tests[test].push(dir)
    else
      puts "Skipping #{dir} ..."
    end
  end
end

configurations_html = build_html("Server configurations", configurations)
workspaces_html     = build_html("Workspaces", workspaces)
tests_html          = build_html("Tests", tests)

File.open(INDEX, 'w') do |file|
  file.write(html_header)
  file.write(workspaces_html)
  file.write(tests_html)
  file.write(configurations_html)
  file.write(html_footer)
end
