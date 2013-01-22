The run_test.rb script has three required arguments: WORKSPACE, TEST and CONFIG. The CONFIG describes the settings to be applied to the server before the test will start and the case describes the particular test that will be run. In all cases, the test will be done for 1-256 concurrent users, with 1000 / sqrt(users) runs per user. A optional argument NODES sets the number of nodes to run the test on; the value can be a set, a range or a combination of both: "1", "1,2,3", "1-5", "1-2,4,7-9". A final optional argument THREADS sets the number of simultaneous users to simulate. This can be a single number or a range.

The WORKSPACE parameter must match the GeoServer config directory under /var/lib/geoserver_data. The TEST, LOOPS, NODES and THREADS parameters will be passed to the run.sh shell script in the WORKSPACE subdirectory in the local cases directory: cases/$WORKSPACE/run.sh.

The follwing CONFIG elements (and known good values) are recognised:
JVM: the Java VM to use
  * /usr/lib/jvm/jdk-1.6.0_37-x64
  - /usr/lib/jvm/jdk-1.6.0_37-x64-nojai
  - /usr/lib/jvm/java-7-oracle
  - /usr/lib/jvm/java-6-openjdk-amd64
  - /usr/lib/jvm/java-7-openjdk-amd64

JAVA_MEM: memory options to be passed to the JVM (default: -Xms128m -Xmx512m -XX:MaxPermSize=128m)

JAVA_GC: garbage collector to use
  * UseParallelGC
  - UseConcMarkSweepGC

JAVA_EXTRA: any further parameters to pass to the JVM

CONTAINER: the servlet container to use
  * tomcat

GLOBAL.featureTypeCacheSize: (default: 0)
GLOBAL.globalServices: 
  * true
  - false
GLOBAL.xmlPostRequestLogBufferSize: (default: 1024)

JAI.interpolation:
  - true
  * false
JAI.recycling:
  - true
  * false
JAI.tilePriority: (default: 5)
JAI.tileThreads: (default: 7)
JAI.memoryCapacity: (default: 0.5)
JAI.memoryThreshold: (default: 0.75)
JAI.imageIOCache:
  - true
  * false
JAI.pngAcceleration:
  - true
  * false
JAI.jpegAcceleration:
  - true
  * false
JAI.allowNativeMosaic:
  - true
  * false

COVERAGE_ACCESS.maxPoolSize: (default: 5)
COVERAGE_ACCESS.corePoolSize: (default: 5)
COVERAGE_ACCESS.keepAliveTime: (default: 30000)
COVERAGE_ACCESS.imageIOCacheThreshold: (default: 10240)
COVERAGE_ACCESS.queueType
  * UNBOUNDED
  - DIRECT

LOGGING.level
  - DEFAULT_LOGGING
  - GEOSERVER_DEVELOPER_LOGGING
  - GEOTOOLS_DEVELOPER_LOGGING
  * PRODUCTION_LOGGING
  - VERBOSE_LOGGING

CONTROLFLOW: turn on the ControlFlow extension
  - true
  * false
CONTROLFLOW.user: no more than this many requests per user (default: 6)
CONTROLFLOW.timeout: max seconds to wait for request to complete (default: 30)
CONTROLFLOW.ows.global: max number of parallel requests (default: 32)
CONTROLFLOW.ows.wms.getmap: max number of parallel GetMap requests (default: 32)
CONTROLFLOW.ows.gwc: max number of parallel tile requests (default: 32)
Other CONTROLFLOW parameters can be set using the same pattern.

WMS.enabled
  * true
  - false
WMS.citeCompliant
  - true
  * false
WMS.interpolation
  * Nearest
  - Bilinear
  - Bicubic
WMS.maxRequestMemory: limit or 0 to disable (default: 0)
WMS.maxRenderingTime: limit or 0 to disable (default: 0)
WMS.maxRenderingErrors: limit or 0 to disable (default: 0)


WFS.enabled
  * true
  - false
WFS.citeCompliant
  - true
  * false
WFS.serviceLevel
  - BASIC
  - TRANSACTIONAL
  * COMPLETE
WFS.maxFeatures: (default: 1000000)
WFS.featureBounding
  - true 
  * false 
WFS.canonicalSchemaLocation
  - true 
  * false 
WFS.encodeFeatureMember
  - true 
  * false 

WCS.enabled
  * true
  - false
WCS.citeCompliant
  - true 
  * false 
WCS.verbose
  - true 
  * false
WCS.gmlPrefixing
  - true 
  * false 
WCS.maxInputMemory: (default 0)
WCS.maxOutputMemory: (default 0)
WCS.subsamplingEnabled
  * true
  - false

=======
TODO: Store configurations
