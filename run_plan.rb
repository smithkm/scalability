#!/usr/bin/ruby
# Run JMeter test plan

require 'rubygems'
require 'fileutils'
require 'optparse'
require 'ostruct'
require 'net/ssh'
require 'rest-client'
require 'json'
require 'pp'

GEOSERVER_USER="admin"
GEOSERVER_PASS="geoserver"
OUT_SUBDIR="results"
BASE_CONF_FILE="base.conf"

TOMCAT_DIR="/srv/tomcat"
TOMCAT_SH="#{TOMCAT_DIR}/tomcat.sh"
TOMCAT_START="#{TOMCAT_DIR}/set_local_node_count.sh"
TOMCAT_CONF="#{TOMCAT_DIR}/tomcat_base/bin/setenv.sh"
DATA_DIR="/var/lib/geoserver_data"

# check if server is responsive
def check_server(retries=20)
  print 'checking server ... '
  until retries < 0
    if Net::HTTP.get_response(URI.parse("#{GEOSERVER_URL}/web/")).kind_of?(Net::HTTPSuccess)
      puts 'response'
      return true
    end
    print "#{retries} "
    STDOUT.flush
    sleep 1
    retries -= 1
  end

  puts 'no response'
  return false
end

# start any necessary nodes (container dependent)
def start_nodes(container, nodes)
  puts "Setting node count to #{nodes} using #{container} ..."
  Net::SSH.start(APP_SERVER, container, :port => 7777 ) do |ssh|
    case container
    when "tomcat"
      ssh.exec!("#{TOMCAT_START} #{nodes}")
    else
      puts "unsupported CONTAINER"
      exit 1
    end
  end

  unless @debug
    # wait a bit for the nodes to come up
    sleep 10 + nodes
  end
end


# read all configurations from file
def read_config(conf_file, conf)
  line_no=0
  File.open(conf_file).each do |line|
    line_no += 1
    line=line.strip
    unless line[0,1] == '#' || line.empty?
      vals=line.split(/=/, 2)
      if vals.size != 2
        puts "ERROR: bad config file #{conf_file} on line #{line_no}: #{line}"
        exit 1
      end
      conf[vals[0]] = vals[1]
    end
  end
end

commandline = ""
ARGV.each do |arg|
  commandline += arg + " "
end

# -d indicated debugging, turn off certain elements
if ARGV.include?("-d")
  puts "DEBUG MODE"
  @debug = true
  BASE_LOOPS=5
  ARGV.delete("-d")
else
  BASE_LOOPS=128
end

# -noconf to disable all configuration of servers using ssh
if ARGV.include?("-nossh")
  ARGV.delete("-nossh")
  SSH=false
  puts "NO AUTOMATIC SERVER CONFIGURATION / NODE STARTING POSSIBLE"
else
  SSH=true
end

# -m indicates a message tag
index = ARGV.index("-m")
if index.nil?
  tag = nil
else
  tag = ARGV[index + 1]
  ARGV.delete_at(index + 1)
  ARGV.delete_at(index)
  puts "Adding tag: #{tag} to test name"
end

# -s server
index = ARGV.index("-s")
if index.nil?
  APP_SERVER_HOST ="scale.dev.opengeo.org"
else
  APP_SERVER_HOST = ARGV[index + 1]
  ARGV.delete_at(index + 1)
  ARGV.delete_at(index)
end

# -p port
index = ARGV.index("-p")
if index.nil?
  APP_SERVER_PORT="80"
else
  APP_SERVER_PORT = ARGV[index + 1]
  ARGV.delete_at(index + 1)
  ARGV.delete_at(index)
end

# -c configuration server that will be accessed by ssh
index = ARGV.index("-c")
if index.nil?
  SSH_SERVER=APP_SERVER_HOST
else
  SSH_SERVER= ARGV[index + 1]
  ARGV.delete_at(index + 1)
  ARGV.delete_at(index)
end

GEOSERVER_URL="http://#{APP_SERVER_HOST}:#{APP_SERVER_PORT}/geoserver"
REST_URL="http://#{GEOSERVER_USER}:#{GEOSERVER_PASS}@#{APP_SERVER_HOST}:#{APP_SERVER_PORT}/geoserver/rest"

unless ARGV[0] && ARGV[1] && ARGV[2]
  puts "ERROR: missing parameter"
  puts "usage: CONFIGURATION WORKSPACE TEST [NODES] [THREADS] [BASE LOOPS]"
  puts "       [-d] [-nossh] [-m MESSAGE] [-s SERVER] [-p PORT] [-c CONFIG_SERVER]"
  exit 1 
end

pwd = Dir.pwd

# set default configurations and read custom config file
conf = Hash.new 
read_config(BASE_CONF_FILE, conf)
configs = ARGV[0]
configs.split(",").each do | config |
  file = "config/#{config}"
  if File.exists?(file)
    read_config(file, conf)
  else
    puts "unable to find config #{file}"
    exit 1
  end
end
configs = configs.gsub(/,/, '.')

# check test case directory
workspace = ARGV[1]
workspace_dir="#{pwd}/workspaces/#{workspace}"
unless File.exists?("#{workspace_dir}/run.sh")
  puts "there should be a run.sh in the target workspace directory: #{workspace_dir}"
  exit 1
end

# set test case
test = ARGV[2]

# set number nodes to test; 1-10 by default otherwise as arg
if ARGV[3]
  node_cfg = [ ]
  args=ARGV[3].split(',')
  args.each { |arg|
    if arg.include?('-')
      range = arg.split('-')
      if range[0].to_i < range[1].to_i
        for i in range[0].to_i..range[1].to_i
          node_cfg.push(i)
        end
      end
    else
      node_cfg.push(arg.to_i)
    end
  }
  node_cfg.delete_if { |n| n < 1 || n > 10 }
  node_cfg = node_cfg.uniq.sort
else
  node_cfg = [ ]
  for n in 1..10
    node_cfg.push(n)
  end
end

# set the number of threads to simulate; 1-128 by default
if ARGV[4]
  range=ARGV[4].split('-')
  if range.size == 1
    min_threads = range[0].to_i
    max_threads = range[0].to_i
  else
    min_threads = range[0].to_i
    max_threads = range[1].to_i
  end
else
  min_threads=1
  max_threads=128
end

if ARGV[5]
  base_loops = ARGV[5].to_i
else
  base_loops = BASE_LOOPS
end

outname = Time.now.strftime("%Y%m%d-%H%M%S-#{configs}-#{ARGV[1].gsub('-', '_')}-#{ARGV[2].gsub('-', '_')}")
if not tag.nil?
  outname = outname + "-#{tag}"
end
outdir = "#{pwd}/#{OUT_SUBDIR}/#{outname}"
FileUtils.mkdir_p(outdir)

# write settings to output directory
conf_list = []
conf.each { |key, val|
  conf_list.push"#{key}=#{val}"
}
conf_list = conf_list.sort

File.open("#{outdir}/plan.txt", 'w') { |file|
  file.write("command=#{commandline}\n")
  file.write("workspace=#{workspace}\n")
  file.write("test=#{test}\n")
  conf_list.each { |line|
    file.write("#{line}\n")
  }
}

if SSH
  # set up a tomcat container
  if conf["CONTAINER"] == "tomcat"
    Net::SSH.start(SSH_SERVER, "tomcat", :port => 7777 ) do |ssh|
      unless @debug
        puts "Shutting down running nodes ..."
        ssh.exec("pkill java")
        ssh.exec!("pkill -9 java") if check_server(20)
        if check_server(5)
  	puts "Server still running ... aborting"
          exit 1
        end
      end
  
      puts "Setting JAVA options ..."
      ssh.exec!("sed -i \"s/^JAVA_HOME=.*/JAVA_HOME=\\\"\\/usr\\/lib\\/jvm\\/#{conf["JVM"]}\\\"/\" #{TOMCAT_SH}")
      ssh.exec!("sed -i \"s/^JAVA_MEM=.*/JAVA_MEM=\\\"#{conf["JAVA_MEM"]}\\\"/\" #{TOMCAT_CONF}")
      ssh.exec!("sed -i \"s/^JAVA_GC=.*/JAVA_GC=\\\"#{conf["JAVA_GC"]}\\\"/\" #{TOMCAT_CONF}")
      ssh.exec!("sed -i \"s/^JAVA_EXTRA=.*/JAVA_EXTRA=\\\"#{conf["JAVA_EXTRA"]}\\\"/\" #{TOMCAT_CONF}")
      ssh.exec!("sed -i \"s/^GEOSERVER_DIR=.*/GEOSERVER_DIR=\\\"\\/var\\/lib\\/geoserver_data\\/#{workspace}\\\"/\" #{TOMCAT_CONF}")
    end
  else
    puts "Unsupported container #{conf["CONTAINER"]} ... aborint"
    exit 1
  end
  
  # generic config for all containers (container name must be same as user)
  Net::SSH.start(SSH_SERVER, conf["CONTAINER"], :port => 7777 ) do |ssh|
    # some configurations need to occur before any nodes are brought up
    # set up control flow
    controlflow_conf="#{DATA_DIR}/#{workspace}/controlflow.properties"
    ssh.exec!("rm #{controlflow_conf}")
    if conf["CONTROLFLOW"] == "true"
      puts "Turning on ControlFlow ..."
      conf.each { |key, val|
        if key.start_with?("CONTROLFLOW.")
          ssh.exec!("echo \"#{key.gsub(/^CONTROLFLOW./, '')}=#{val}\" >> #{controlflow_conf}")
        end
      }
    end
  
    # set logging
    puts "Set logging level ..."
    log_conf="#{DATA_DIR}/#{workspace}/logging.xml"
    level = conf["LOGGING.level"] + ".properties"
    ssh.exec!("sed -i \"s/<level>.*<\\\/level>/<level>#{level}<\\\/level>/\" #{log_conf}")
  end
  
  
  # start up the first node so we can initialise via the rest api
  # configure global settings
  puts "Starting first node ..."
  start_nodes(conf["CONTAINER"], 1)
  unless check_server
    puts "Server is not responding ... aborting tests"
    exit 1
  end
end

puts "Configuring settings via REST..."
geoserver_settings = JSON.parse(RestClient.get("#{REST_URL}/settings.json"))
geoserver_global = geoserver_settings["global"]
jai_settings = geoserver_global["jai"]
coverageAccess_settings = geoserver_global["coverageAccess"]
conf.each { |key, val|
  if key.start_with?("GLOBAL.")
    geoserver_global[key.gsub(/^GLOBAL./, '')] = val
  elsif key.start_with?("JAI.")
    jai_settings[key.gsub(/^JAI./, '')] = val
  elsif key.start_with?("COVERAGE_ACCESS.")
    coverageAccess_settings[key.gsub(/^COVERAGE_ACCESS./, '')] = val
  end
}
RestClient.put "#{REST_URL}/settings.json", geoserver_settings.to_json, :content_type => :json

puts "Configuring WMS settings via REST..."
geoserver_settings = JSON.parse(RestClient.get("#{REST_URL}/services/wms/settings.json"))
geoserver_wms = geoserver_settings["wms"]
conf.each { |key, val|
  if key.start_with?("WMS.")
    geoserver_wms[key.gsub(/^WMS./, '')] = val
  end
}
RestClient.put "#{REST_URL}/services/wms/settings.json", geoserver_settings.to_json, :content_type => :json

#puts "Configuring WFS settings via REST..."
#geoserver_settings = JSON.parse(RestClient.get("#{REST_URL}/services/wfs/settings.json"))
#geoserver_wfs = geoserver_settings["wfs"]
#conf.each { |key, val|
#  if key.start_with?("WFS.")
#    geoserver_wfs[key.gsub(/^WFS./, '')] = val
#  end
#}
#RestClient.put "#{REST_URL}/services/wfs/settings.json", geoserver_settings.to_json, :content_type => :json

puts "Configuring WCS settings via REST..."
geoserver_settings = JSON.parse(RestClient.get("#{REST_URL}/services/wcs/settings.json"))
geoserver_wcs = geoserver_settings["wcs"]
conf.each { |key, val|
  if key.start_with?("WCS.")
    geoserver_wcs[key.gsub(/^WCS./, '')] = val
  end
}
RestClient.put "#{REST_URL}/services/wcs/settings.json", geoserver_settings.to_json, :content_type => :json

# ensure that changes take effect
puts "Reload catalog changes"
RestClient.put("#{REST_URL}/reload", '')

Dir.chdir("workspaces/#{workspace}")
gnuplot_cmd_base  = "set size 1,1;"
gnuplot_cmd_base += "set terminal png size 760,640 nocrop enhanced;"
gnuplot_cmd_base += "set xrange[#{min_threads}:#{max_threads}];"
gnuplot_cmd_base += "set xlabel 'Concurrent users';"
gnuplot_cmd_base += "set ylabel 'Response time (ms)';"
gnuplot_cmd_base += "set datafile separator ',';"
gnuplot_cmd_all = "plot "

# remove any old results
Dir.glob("#{workspace_dir}/summary_*.csv").each { |file|
  FileUtils.rm(file)
}

# run the test for each number of nodes
results_table = ""
node_cfg.each { |nodes|
  unless nodes == 1
    start_nodes(conf["CONTAINER"], nodes) if SSH
  end
  sleep 10
  threads=min_threads

  results="%02d_nodes.csv" % nodes
  until threads > max_threads
    # let the number of loops decrease slowly based on the number of threads
    loops = (base_loops / (threads ** (0.25))).to_i
    puts "Starting test: workspace=#{workspace} test=#{test} nodes=#{nodes} threads=#{threads} loops=#{loops} ..."

    nodes_s = "%02d" % nodes
    threads_s = "%03d" % threads
    loops_s = "%04d" % loops
    unless system("./run.sh #{test} #{nodes_s} #{threads_s} #{loops_s} #{APP_SERVER_HOST} #{APP_SERVER_PORT}")
      puts "Error running test... aborting"
      exit 1
    end
    system("#{pwd}/aggregate.rb #{workspace_dir}/summary_#{nodes_s}_#{threads_s}.csv >> #{outdir}/#{results}")
    threads *= 2
  end 

  # build gnuplot command for individual and composite plots
  gnuplot_cmd = "'#{outdir}/#{results}' using 1:4 with linespoints title '#{nodes} node(s)'"
  gnuplot_cmd_all += "#{gnuplot_cmd},"

  # plot this node's results
  system("echo \"#{gnuplot_cmd_base}; set output '#{outdir}/#{nodes_s}_nodes.png';plot #{gnuplot_cmd};\" | gnuplot")
  
  puts "Results written to #{results} ..."
}

# archive raw data
FileUtils.mkdir_p("#{outdir}/data")
Dir.glob("#{workspace_dir}/summary_*.csv").each { |file|
  FileUtils.mv(file, "#{outdir}/data/")
}
FileUtils.mkdir_p("#{outdir}/logs")
Dir.glob("#{workspace_dir}/*.log").each { |file|
  FileUtils.mv(file, "#{outdir}/logs/")
}

# plot all data and save gnuplot commands
gnuplot_cmd_all = gnuplot_cmd_base + "set output '#{outdir}/plot.png';" + gnuplot_cmd_all.chomp(",") + ";"
system("echo \"#{gnuplot_cmd_all}\" | gnuplot")
File.open("#{outdir}/logs/gnuplot.log", 'w') { |file|
  file.write(gnuplot_cmd_all.gsub(";", "\n"))
}

# create webpage from template
# build config in html
conf_html = "<br/>"
File.open("#{outdir}/plan.txt", 'w') { |file|
  file.write("workspace=#{workspace}\n")
  file.write("test=#{test}\n")
  conf_list.each { |line|
    file.write("#{line}\n")
    conf_html += "#{line}<br/>"
  }
}

# collect all results
results_html  = ""
node_cfg.each { |nodes|
  nodes_s = "%02d" % nodes
  results_html += "<h2>#{nodes_s} nodes</h2>\n"
  results_html += "<a href=\"#{nodes_s}_nodes.csv\">csv data</a>\n"
  results_html += "<table>\n"
  results_html += "<tr>\n"
  results_html += "<td>\n"
  results_html += "<a href=\"#{nodes_s}_nodes.png\"><img width=\"240px\" src=\"#{nodes_s}_nodes.png\"/></a>"
  results_html += "</td>\n"
  results_html += "<td valign=\"top\">\n"
  results_html += "<table>\n"
  results_html += "<tr>\n"
  results_html += "<td>Threads</td>\n"
  results_html += "<td>Requests</td>\n"
  results_html += "<td>Errors</td>\n"
  results_html += "<td>Avgerage</td>\n"
  results_html += "<td>Median</td>\n"
  results_html += "<td>90 Percentile</td>\n"
  results_html += "<td>Minimum</td>\n"
  results_html += "<td>Maximum</td>\n"
  results_html += "<td>Duration</td>\n"
  results_html += "<td>Throughput</td>\n"
  results_html += "<td>Data Rate</td>\n"
  results_html += "</tr>\n"
  File.open("#{outdir}/#{nodes_s}_nodes.csv", 'r').each { |line|
    results_html += "<tr>\n<td>"
    results_html += line.gsub(",","</td>\n<td>")
    results_html += "</td>\n</tr>\n"
  }
  results_html += "</table>\n"
  results_html += "</td>\n"
  results_html += "</tr>\n"
  results_html += "</table>\n"
}

File.open("#{outdir}/index.html", 'w') { |fout| 
  File.open("#{pwd}/index.html.template", "r").each_line do |line_in|
    line_out = line_in.gsub("${name}", outname).gsub("${config}", conf_html).gsub("${results}", results_html).gsub("${workspace}", workspace).gsub("${test}", test).gsub("${setup}", configs)
    fout.write(line_out) 
  end
}

# update the index in the results directory
system("#{pwd}/update_index.rb #{pwd}/#{OUT_SUBDIR}")
