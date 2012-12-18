#!/usr/bin/env ruby
require "cgi"
require "set"
require "fileutils"

@cgi = CGI.new("html4")

def output_error(title, message)
  @cgi.out{
    @cgi.html{
      @cgi.head{ "\n"+@cgi.title{"Script error"} } +
      @cgi.body{
        @cgi.h1 { "Error: #{title}" } +
        @cgi.p { message }
      }
    }
  }
end

dirs = @cgi.params['dir[]'].uniq.sort

# check for arguments
if dirs.empty? || dirs.size < 2
  output_error("incorrect arguments", "at least 2 tests must be selected<br\>dirs=#{dirs.to_s}")
  exit 1
end

dirs.each do |dir|
  unless File.directory?(dir)
    output_error("missing directory", "couldn't find #{dir}")
    exit 1
  end
end

nodes = @cgi.params['nodes']
if nodes.empty? 
  output_error("incorrect arguments", "nodes must be between 1 and 10")
  exit 1
end

# find common elements in all dirs
configurations = Set.new
workspaces = Set.new
tests = Set.new
dirs.each do |dir|
  parts = dir.split("-")
  if parts.size == 5
    configurations.add(parts[2])
    workspaces.add(parts[3] )
    tests.add(parts[4] )
  end
end

title_parts = [ 0, 1 ]
title = ""
if configurations.size == 1
  title += "config: #{configurations.first} "
else 
  title_parts.push(2)
end
if workspaces.size == 1
  title += "workspace: #{workspaces.first} "
else 
  title_parts.push(3)
end
if tests.size == 1
  title += "test: #{tests.first} "
else 
  title_parts.push(4)
end

gnuplot = <<-EOD
set size 1,1;
set terminal png size 760,640 nocrop enhanced;
set xrange[1:128];
set xlabel 'Concurrent users';
set ylabel 'Response time (ms)';
set datafile separator ',';
set key reverse left Left width 1 box 3;
set grid;
EOD

gnuplot += "set title \'#{title.gsub('_', '\\_')}\';"
gnuplot += "plot "

dirs.each do |dir|
  parts = dir.split("-")
  title = ""
  title_parts.each do |part|
    title += parts[part].gsub('_', '\\_') + "-"
  end
  gnuplot += "'#{dir}/%02d_nodes.csv' using 1:4 with linespoints title '#{title.chomp('-')}' ," % nodes
end
gnuplot = gnuplot.chomp(",") + ";"
#@cgi.out{ gnuplot }

png = `echo \"#{gnuplot}\" | gnuplot`
@cgi.header('Content-Disposition' => 'attachment;filename=plot.png')
@cgi.out( "type" => "image/png", "expires" => Time.now + 3600 ) { png }
