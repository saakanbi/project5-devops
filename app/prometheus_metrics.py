from prometheus_client import Counter, Gauge, generate_latest, CONTENT_TYPE_LATEST, REGISTRY, GC_COLLECTOR
from prometheus_client.core import GaugeMetricFamily, CounterMetricFamily
import gc
import os
import psutil
import time

# Register GC collector
GC_COLLECTOR.register()

# Application metrics
REQUEST_COUNT = Counter('app_requests_total', 'Total app requests')
DASHBOARD_VIEWS = Counter('app_dashboard_views_total', 'Dashboard page views')

# Flask HTTP request metrics
HTTP_REQUEST_TOTAL = Counter('flask_http_request_total', 'Total HTTP requests', 
                            ['method', 'endpoint', 'status'])

# Process metrics
PROCESS_CPU_SECONDS = Counter('process_cpu_seconds_total', 'Total user and system CPU time spent in seconds.')
PROCESS_VIRTUAL_MEMORY = Gauge('process_virtual_memory_bytes', 'Virtual memory size in bytes.')
PROCESS_RESIDENT_MEMORY = Gauge('process_resident_memory_bytes', 'Resident memory size in bytes.')
PROCESS_START_TIME = Gauge('process_start_time_seconds', 'Start time of the process since unix epoch in seconds.')
PROCESS_OPEN_FDS = Gauge('process_open_fds', 'Number of open file descriptors.')
PROCESS_MAX_FDS = Gauge('process_max_fds', 'Maximum number of open file descriptors.')

# Python GC metrics
GC_OBJECTS_COLLECTED = Counter('python_gc_objects_collected_total', 'Objects collected during gc', ['generation'])
GC_OBJECTS_UNCOLLECTABLE = Counter('python_gc_objects_uncollectable_total', 'Uncollectable objects found during GC', ['generation'])
GC_COLLECTIONS = Counter('python_gc_collections_total', 'Number of times this generation was collected', ['generation'])

# Python info
PYTHON_INFO = Gauge('python_info', 'Python platform information', 
                   ['implementation', 'major', 'minor', 'patchlevel', 'version'])

# Initialize metrics
PYTHON_INFO.labels(
    implementation='CPython',
    major='3',
    minor='7',
    patchlevel='16',
    version='3.7.16'
).set(1)

# Set process start time
process = psutil.Process(os.getpid())
PROCESS_START_TIME.set(process.create_time())

def update_metrics():
    """Update all metrics with current values"""
    # Update process metrics
    PROCESS_CPU_SECONDS.inc(process.cpu_times().user + process.cpu_times().system)
    PROCESS_VIRTUAL_MEMORY.set(process.memory_info().vms)
    PROCESS_RESIDENT_MEMORY.set(process.memory_info().rss)
    PROCESS_OPEN_FDS.set(len(process.open_files()))
    PROCESS_MAX_FDS.set(process.rlimit(psutil.RLIMIT_NOFILE)[1])

def get_metrics():
    """Generate latest metrics"""
    update_metrics()
    return generate_latest(REGISTRY)