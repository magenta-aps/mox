# Settings for gunicorn in docker.
import multiprocessing


bind = "0.0.0.0:8080"
workers = multiprocessing.cpu_count() * 2 + 1
accesslog =  "/log/access.log"
worker_tmp_dir = "/dev/shm"
