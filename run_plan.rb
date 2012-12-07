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

@base_loops=6
@ap_server="scale.dev.opengeo.org"
@db_server="scale-db.dev.opengeo.org"
@geoserver_user="admin"
@geoserver_pass="geoserver"
@geoserver_url="http://#{@ap_server}/geoserver"
@rest_url="http://#{@geoserver_user}:#{@geoserver_pass}@#{@ap_server}/geoserver/rest"
@out_dir="results"

@tomcat_dir="/srv/tomcat"
@tomcat_sh="#{@tomcat_dir}/tomcat.sh"
@tomcat_start="#{@tomcat_dir}/set_local_node_count.sh"
@tomcat_conf="#{@tomcat_dir}/tomcat_base/bin/setenv.sh"
@data_dir="/var/lib/geoserver_data"

# default configurations
conf = Hash.new 
conf["JVM"] = "jdk-1.6.0_37-x64"
conf["JAVA_MEM"] = "-Xms128m -Xmx512m -XX:MaxPermSize=128m"
conf["JAVA_GC"] = "UseParallelGC"
conf["JAVA_EXTRA"] = ""
conf["GLOBAL.featureTypeCacheSize"] = 0
conf["GLOBAL.globalServices"] = "true" 
conf["GLOBAL.xmlPostRequestLogBufferSize"] = 1024
conf["JAI.allowInterpolation"] = "false"
conf["JAI.recycling"] = "false"
conf["JAI.tilePriority"] = 5
conf["JAI.tileThreads"] = 7
conf["JAI.memoryCapacity"] = 0.5
conf["JAI.memoryThreshold"] = 0.75
conf["JAI.imageIOCache"] = "false"
conf["JAI.pngAcceleration"] = "false"
conf["JAI.jpegAcceleration"] = "false"
conf["JAI.allowNativeMosaic"] = "false"
conf["COVERAGE_ACCESS.maxPoolSize"] = 5
conf["COVERAGE_ACCESS.corePoolSize"] = 5
conf["COVERAGE_ACCESS.keepAliveTime"] = 30000
conf["COVERAGE_ACCESS.imageIOCacheThreshold"] = 10240
conf["COVERAGE_ACCESS.queueType"] = "UNBOUNDED"
conf["CONTAINER"] = "tomcat"
conf["CONTROLFLOW"] = "false"
conf["CONTROLFLOW.user"] = 6
conf["CONTROLFLOW.timeout"] = 30
conf["CONTROLFLOW.ows.gwc"] = 32
conf["CONTROLFLOW.ows.global"] = 32
conf["CONTROLFLOW.ows.wms.getmap"] = 32
conf["LOGGING.level"] = "PRODUCTION_LOGGING"

# check if server is responsive
def check_server(retries=20)
  until retries < 0
    return true if Net::HTTP.get_response(URI.parse("#{@geoserver_url}/web/")).kind_of?(Net::HTTPSuccess)
    sleep 1
    retries -= 1
  end

  return false
end

# start any necessary nodes (container dependent)
def start_nodes(container, nodes)
  puts "Setting node count to #{nodes} using #{container} ..."
  Net::SSH.start(@ap_server, container, :port => 7777 ) do |ssh|
    case container
    when "tomcat"
      ssh.exec!("#{@tomcat_start} #{nodes}")
    else
      puts "unsupported CONTAINER"
      exit 1
    end
  end

  # wait a bit for the nodes to come up
  sleep 10 + nodes
end

unless ARGV[0] && ARGV[1] && ARGV[2]
  puts "ERROR: missing parameter"
  puts "usage: CONFIGURATION WORKSPACE TEST [NODES] [THREADS]"
  exit 1 
end

pwd = Dir.pwd

# read config file
conf_file = "config/#{ARGV[0]}"
if File.exists?(conf_file)
  line_no=0
  File.open(conf_file).each do |line|
    line_no += 1
    line=line.strip
    unless line[0,1] == '#' || line.empty?
      vals=line.split(/=/, 2)
      if vals.size != 2
        puts "ERROR: bad config file on line #{line_no}: #{line}"
        exit 1
      end
      conf[vals[0]] = vals[1]
    end
  end
else
  puts "unable to find config file"
  exit 1
end

# check test case directory
workspace = ARGV[1]
workspace_dir="#{pwd}/workspaces/#{workspace}"
unless File.exists?("#{workspace_dir}/run.sh")
  puts "there should be a run.sh in the target workspace directory: #{workspace_dir}"
  exit 1
end

# set test case
test = ARGV[2]

# set number nodes to test; 1 by default otherwise as arg
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
  node_cfg.delete_if { |n| n < 0 }
  node_cfg = node_cfg.uniq.sort
else
  node_cfg = [ 1 ]
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

outname = Time.now.strftime("%Y%m%d-%H%M%S-#{ARGV[0]}-#{ARGV[1]}-#{ARGV[2]}")
outdir = "#{pwd}/#{@out_dir}/#{outname}"
FileUtils.mkdir_p(outdir)

# write settings to output directory
conf_list = []
conf.each { |key, val|
  conf_list.push"#{key}=#{val}"
}
conf_list = conf_list.sort

conf_html = "<br/>"
File.open("#{outdir}/plan.txt", 'w') { |file|
  file.write("workspace=#{workspace}\n")
  file.write("test=#{test}\n")
  conf_list.each { |line|
    file.write("#{line}\n")
    conf_html += "#{line}<br/>"
  }
}

# set up a tomcat container
if conf["CONTAINER"] == "tomcat"
  Net::SSH.start(@ap_server, "tomcat", :port => 7777 ) do |ssh|
    puts "Shutting down running nodes ..."
    ssh.exec!("pkill java")
    sleep 10

    puts "Setting JAVA options ..."
    ssh.exec!("sed -i \"s/^JAVA_HOME=.*/JAVA_HOME=\\\"\\/usr\\/lib\\/jvm\\/#{conf["JVM"]}\\\"/\" #{@tomcat_sh}")
    ssh.exec!("sed -i \"s/^JAVA_MEM=.*/JAVA_MEM=\\\"#{conf["JAVA_MEM"]}\\\"/\" #{@tomcat_conf}")
    ssh.exec!("sed -i \"s/^JAVA_GC=.*/JAVA_GC=\\\"#{conf["JAVA_GC"]}\\\"/\" #{@tomcat_conf}")
    ssh.exec!("sed -i \"s/^JAVA_EXTRA=.*/JAVA_EXTRA=\\\"#{conf["JAVA_EXTRA"]}\\\"/\" #{@tomcat_conf}")
    ssh.exec!("sed -i \"s/^GEOSERVER_DIR=.*/GEOSERVER_DIR=\\\"\\/var\\/lib\\/geoserver_data\\/#{workspace}\\\"/\" #{@tomcat_conf}")
  end
end

# generic config for all containers (container name must be same as user)
Net::SSH.start(@ap_server, conf["CONTAINER"], :port => 7777 ) do |ssh|
  # some configurations need to occur before any nodes are brought up
  # set up control flow
  controlflow_conf="#{@data_dir}/#{workspace}/controlflow.properties"
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
  log_conf="#{@data_dir}/#{workspace}/logging.xml"
  level = conf["LOGGING.level"]
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

puts "Configuring initial settings ..."
geoserver_settings = JSON.parse(RestClient.get("#{@rest_url}/settings.json"))
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
RestClient.put "#{@rest_url}/settings.json", geoserver_settings.to_json, :content_type => :json

Dir.chdir("workspaces/#{workspace}")
gnuplot_cmd_base  = "set size 1,1;"
gnuplot_cmd_base += "set terminal png size 640,640;"
gnuplot_cmd_base += "set xrange[#{min_threads}:#{max_threads}];"
gnuplot_cmd_base += "set xlabel 'Concurrent users';"
gnuplot_cmd_base += "set ylabel 'Response time (ms)';"
gnuplot_cmd_base += "set datafile separator ',';"
gnuplot_cmd_all = "plot "

# run the test for each number of nodes
results_table = ""
new_row=true
node_cfg.each { |nodes|
  unless nodes == 1
    start_nodes(conf["CONTAINER"], nodes) 
  end
  threads=min_threads

  results="%02d_nodes.csv" % nodes
  until threads > max_threads
    # let the number of loops decrease slowly based on the number of threads
    loops = (@base_loops / (threads ** (0.25))).to_i
    puts "Starting test: workspace=#{workspace} test=#{test} nodes=#{nodes} threads=#{threads} loops=#{loops} ..."

    nodes_s = "%02d" % nodes
    threads_s = "%03d" % threads
    loops_s = "%04d" % loops
    unless system("./run.sh #{test} #{nodes_s} #{threads_s} #{loops_s}")
      puts "Error running test... aborting"
      exit 1
    end
    system("#{pwd}/aggregate.rb #{workspace_dir}/summary_#{nodes_s}_#{threads_s}.csv >> #{outdir}/#{results}")
    threads *= 2
  end 

  # build gnuplot commands
  gnuplot_cmd = "'#{outdir}/#{results}' using 1:4 with linespoints title '#{nodes} node(s)'"
  gnuplot_cmd_all += "#{gnuplot_cmd},"
  system("echo \"#{gnuplot_cmd_base}; set output '#{outdir}/#{nodes_s}_nodes.png';plot #{gnuplot_cmd};\" | gnuplot")
  
  if new_row
    results_table += "<tr>"
  end
  results_table += "<td><a href=\"#{results}\">#{nodes} nodes</a><br/><a href=\"#{nodes_s}_nodes.png\"><img width=\"66%\" src=\"#{nodes_s}_nodes.png\"/></a></td>"
  if new_row
    new_row = false
  else
    results_table += "</tr>"
    new_row = true
  end
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

# plot results
gnuplot_cmd_all = gnuplot_cmd_base + "set output '#{outdir}/plot.png';" + gnuplot_cmd_all.chomp(",") + ";"
system("echo \"#{gnuplot_cmd_all}\" | gnuplot")
File.open("#{outdir}/logs/gnuplot.log", 'w') { |file|
  file.write(gnuplot_cmd_all.gsub(";", "\n"))
}

# create webpage from template
#results_table += "</ul>"
File.open("#{outdir}/index.html", 'w') { |fout| 
  File.open("#{pwd}/index.html.template", "r").each_line do |line_in|
    line_out = line_in.gsub("${name}", outname).gsub("${config}", conf_html).gsub("${results}", results_table).gsub("${workspace}", workspace).gsub("${test}", test).gsub("${setup}", conf_file)
    fout.write(line_out) 
  end
}
