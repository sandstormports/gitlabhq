# Sample verbose configuration file for Unicorn (not Rack)
#
# This configuration file documents many features of Unicorn
# that may not be needed for some applications. See
# http://unicorn.bogomips.org/examples/unicorn.conf.minimal.rb
# for a much simpler configuration file.
#
# See http://unicorn.bogomips.org/Unicorn/Configurator.html for complete
# documentation.

# Note: If you change this file in a Merge Request, please also create a
# Merge Request on https://gitlab.com/gitlab-org/omnibus-gitlab/merge_requests
#
# WARNING: See config/application.rb under "Relative url support" for the list of
# other files that need to be changed for relative url support
#
# ENV['RAILS_RELATIVE_URL_ROOT'] = "/gitlab"

# Read about unicorn workers here:
# http://doc.gitlab.com/ee/install/requirements.html#unicorn-workers
#
worker_processes 3

# Since Unicorn is never exposed to outside clients, it does not need to
# run on the standard HTTP port (80), there is no reason to start Unicorn
# as root unless it's from system init scripts.
# If running the master process as root and the workers as an unprivileged
# user, do this to switch euid/egid in the workers (also chowns logs):
# user "unprivileged_user", "unprivileged_group"

# Help ensure your application will always spawn in the symlinked
# "current" directory that Capistrano sets up.
#working_directory "/home/git/gitlab" # available in 0.94.0+

# Listen on both a Unix domain socket and a TCP port.
# If you are load-balancing multiple Unicorn masters, lower the backlog
# setting to e.g. 64 for faster failover.
#listen "/home/git/gitlab/tmp/sockets/gitlab.socket", :backlog => 1024
#listen "127.0.0.1:8080", :tcp_nopush => true

# nuke workers after 30 seconds instead of 60 seconds (the default)
#
# NOTICE: git push over http depends on this value.
# If you want be able to push huge amount of data to git repository over http
# you will have to increase this value too.
#
# Example of output if you try to push 1GB repo to GitLab over http.
#   -> git push http://gitlab.... master
#
#   error: RPC failed; result=18, HTTP code = 200
#   fatal: The remote end hung up unexpectedly
#   fatal: The remote end hung up unexpectedly
#
# For more information see http://stackoverflow.com/a/21682112/752049
#
timeout 60

# feel free to point this anywhere accessible on the filesystem
pid "/tmp/unicorn.pid"


# combine Ruby 2.0.0dev or REE with "preload_app true" for memory savings
# http://rubyenterpriseedition.com/faq.html#adapt_apps_for_cow
#preload_app true
#GC.respond_to?(:copy_on_write_friendly=) and
#  GC.copy_on_write_friendly = true

# Enable this flag to have unicorn test client connections by writing the
# beginning of the HTTP headers before calling the application.  This
# prevents calling the application for connections that have disconnected
# while queued.  This is only guaranteed to detect clients on the same
# host unicorn runs on, and unlikely to detect disconnects even on a
# fast LAN.
#check_client_connection false
