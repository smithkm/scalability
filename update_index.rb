#!/usr/bin/ruby
# Set up index.html for results directory

require 'fileutils'
INDEX="index.html"

def build_comparison_html(title, hash)
  html  = "<h2>#{title}</h2>\n"
  html += "<ul>\n"
  
  hash.each do |key, val|
    if val.size > 1
      html += "<li>#{key[0]}, #{key[1]}<ul>"

      list = ""
      val.sort.each do |dir|
        list += "<li><a href=\"#{dir[1]}\">#{dir[0]}</a></li>"
      end
      html += list
      html += "</ul></li>\n"
    end
  end
  
  html += "</ul>\n"
  return html
end

def build_list_html(title, hash)
  html  = "<h2>#{title}</h2>\n"
  html += "<ul>\n"
  
  hash.each do |key, val|
    html += "<li>#{key}<ul>"
    val.each do |dir|
      html += "<li><input type=\"checkbox\" name=\"dir\[\]\" value=\"#{dir}\"><a href=\"#{dir}\">#{dir}</a></li>"
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
  <form name="input" action="compare.rb" method="get">
EOD

html_footer = <<-EOD
  <br/>
  <select name="nodes">
    <option value="1">1</option>
    <option value="2">2</option>
    <option value="3">3</option>
    <option value="4">4</option>
    <option value="5">5</option>
    <option value="6">6</option>
    <option value="7">7</option>
    <option value="8">8</option>
    <option value="9">9</option>
    <option value="10">10</option>
  </select>
  <input type="submit" value="Compare...">
  </form>
</body>
EOD

plans = []
configurations = Hash.new
workspaces = Hash.new
tests = Hash.new

wc_pairs = Hash.new
wt_pairs = Hash.new

Dir.glob("*").each do |dir|
  if File.directory?(dir)
    parts = dir.split("-")
    if parts.size == 5
      puts "Adding #{dir} ..."
      plans.push(dir)
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

      # not interested in comparing when configuration and test are the same
      key = [ workspace, configuration ]
      unless wc_pairs.has_key?(key)
        wc_pairs[ key ] = []
      end
      wc_pairs[key].push([test, dir])

      key = [ workspace, test ]
      unless wt_pairs.has_key?(key)
        wt_pairs[key] = []
      end
      wt_pairs[key].push([configuration, dir])
    else
      puts "Skipping #{dir} ..."
    end
  end
end

wt_pairs_html = build_comparison_html("Configuration Comparison", wt_pairs)
wc_pairs_html = build_comparison_html("Test Comparison", wc_pairs)

configurations_html = build_list_html("Server configurations", configurations)
workspaces_html     = build_list_html("Workspaces", workspaces)
tests_html          = build_list_html("Tests", tests)

File.open(INDEX, 'w') do |file|
  file.write(html_header)
  file.write(wt_pairs_html)
  file.write(wc_pairs_html)
  file.write("<hr/>")
  file.write(workspaces_html)
  file.write(tests_html)
  file.write(configurations_html)
  file.write(html_footer)
end
