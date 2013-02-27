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
comp  = @cgi['comp']
max   = @cgi['max']
min   = @cgi['min']

if min.empty?
  min = "1"
end

if max.empty?
  max = "128"
end

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
set xlabel 'Concurrent users';
set datafile separator ',';
set key reverse left Left width 1 box 3;
set grid;
EOD

case comp
when "3"
  ylabel = "Errors"
when "4"
  ylabel = "Response time (ms)"
when "5"
  ylabel = "Median response time (ms)"
when "6"
  ylabel = "90% response time (ms)"
when "7"
  ylabel = "Min response time (ms)"
when "8"
  ylabel = "Max response time (ms)"
when "9"
  ylabel = "Total duration (ms)"
when "10"
  ylabel = "Throughput"
when "11"
  ylabel = "Data rate"
else
  ylabel = "#{comp}"
end

gnuplot += "set xrange[#{min}:#{max}];"
gnuplot += "set ylabel \'#{ylabel}\';"
gnuplot += "set title \'#{title.gsub('_', '\\_')}\';"
gnuplot += "plot "

dirs.each do |dir|
  parts = dir.split("-")
  title = ""
  title_parts.each do |part|
    title += parts[part].gsub('_', '\\_') + "-"
  end
  gnuplot += "'#{dir}/%02d_nodes.csv' using 1:#{comp[0]} with linespoints title '#{title.chomp('-')}' ," % nodes
end
gnuplot = gnuplot.chomp(",") + ";"
#@cgi.out{ gnuplot }

png = `echo \"#{gnuplot}\" | gnuplot`
@cgi.header('Content-Disposition' => 'attachment;filename=plot.png')
@cgi.out( "type" => "image/png", "expires" => Time.now + 3600 ) { png }
