#!/usr/bin/ruby -w
# Aggregate JMeter results

require 'fileutils'
require 'optparse'
require 'ostruct'

unless ARGV[0] 
  puts "ERROR: missing parameter"
  puts "usage: INPUT"
  exit 1
end

file=ARGV[0]
@results = Hash.new 

def aggregate(name, timestamp, loadtime, bytes, latency, samples, errors)
  group=name.gsub(/[0-9]*[-].+$/, '').strip

  unless @results.has_key?(group)
    @results[group] = OpenStruct.new
    @results[group].samples = 0
    @results[group].errors = 0
    @results[group].bytes = 0
    @results[group].latency = 0
    @results[group].loadtime = 0
    @results[group].min_loadtime = loadtime
    @results[group].max_loadtime = loadtime
    @results[group].start_time = timestamp
    @results[group].end_time = timestamp
    @results[group].times = []
  end

  @results[group].samples  += samples
  @results[group].errors   += errors
  @results[group].bytes    += bytes
  @results[group].latency  += latency
  @results[group].loadtime += loadtime
  @results[group].times.push(loadtime)

  if loadtime > @results[group].max_loadtime
    @results[group].max_loadtime = loadtime
  end
  if loadtime < @results[group].min_loadtime
    @results[group].min_loadtime = loadtime
  end

  if timestamp > @results[group].end_time
    @results[group].end_time = timestamp
  end
  if timestamp < @results[group].start_time
    @results[group].start_time = timestamp
  end
end

# read environment configuration file (optional)
if File.exists?(file)
  File.open(file, "r").each_line { |line| 
    csv=line.split(",") 
    aggregate(csv[2], csv[0].to_i, Integer(csv[1]), Integer(csv[3]), Integer(csv[4]), Integer(csv[5]), Integer(csv[6]));
  }
end

@results.each { |group, result|
  error_rate = result.errors.to_f / result.samples
  avg_loadtime = result.loadtime.to_f / result.samples
  duration = result.end_time - result.start_time + avg_loadtime # close enough
  throughput = result.samples / duration.to_f * 1000
  data_rate = result.bytes.to_f / duration.to_f
  times = result.times.sort
  median = times[ times.size / 2 ] # close enough
  nintyperc = times[ times.size * 9 / 10 ] # close enough
  puts "#{group},#{result.samples},#{result.errors},#{avg_loadtime},#{median},#{nintyperc},#{result.min_loadtime},#{result.max_loadtime},#{duration},#{throughput},#{data_rate}"
}

exit 0
