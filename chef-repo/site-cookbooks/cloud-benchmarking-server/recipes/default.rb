#
# Cookbook Name:: cloud-benchmarking-server
# Recipe:: default
#
# Copyright (C) 2014 seal uzh
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe "apt"
include_recipe "vim"
include_recipe "vagrant"
include_recipe "cbench-databox"
include_recipe "cbench-rackbox"
include_recipe "cbench-nodejs"

# Consider configuring the database.yml based on the chosen database, password and db name here
# instead of pushing this configuration later via Capistrano.



# TODO: A paremetrized loop may be required for multiple workers!?
# Refactor into own recipe later
# Delayed job worker(s)
app = {}
app["appname"] = "cloud_benchmarking" # TODO: Fix hardcoded value.
app_dir = ::File.join(node["appbox"]["apps_dir"], app["appname"], 'current')
home_dir = File.join(node['user']['home_root'], node['appbox']['apps_user']
runit_service "delayed_job" do
	run_template_name  node["cloud-benchmarking-server"]["delayed_job"]["template_name"]
	log_template_name  node["cloud-benchmarking-server"]["delayed_job"]["template_name"]
	cookbook           node["cloud-benchmarking-server"]["delayed_job"]["template_cookbook"]
	options(
		:user                 => node["appbox"]["apps_user"],
		:group                => node["appbox"]["apps_user"],
		:rack_env             => node["cloud-benchmarking-server"]["delayed_job"]["env"],
    :working_directory    => app_dir,
    :service_name         => "delayed_job",
    :home_dir             => home_dir
  )

  # TODO: provide as configurable attribute instead of hardcoding here
  # The BUNDLE_GEMFILE environment variable is required if running rails apps with unicorn.
  # Otherwise unicorn would fail on startup with a 'Bundler::GemfileNotFound' exception searching
  # within another directory for the Gemfile (e.g. searching in 'shared/Gemfile')
  # See: http://blog.willj.net/2011/08/02/fixing-the-gemfile-not-found-bundlergemfilenotfound-error/
  env(
    'BUNDLE_GEMFILE'      => File.join(app_dir, 'Gemfile'),
    'BUNDLE_PATH'         => File.absolute_path(File.join(app_dir, '../shared/vendor/bundle')), # Symlinked to shared/vendor/bundle
    'RAILS_ENV'           => 'production',
    'HOME'                => home_dir)
  )
	restart_on_update false
end