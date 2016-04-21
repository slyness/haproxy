#
# Cookbook Name:: haproxy
# Recipe:: app_lb
#
# Copyright 2011, Heavy Water Operations, LLC.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe "haproxy::install_#{node['haproxy']['install_method']}"
include_recipe "haproxy::_discovery"

pool = ["options httpchk #{node['haproxy']['httpchk']}"] if node['haproxy']['httpchk']

servers = node['haproxy']['pool_members'].uniq.map do |s|
  "#{s[:hostname]} #{s[:ipaddress]}:#{node['haproxy']['member_port']} weight 1 maxconn #{node['haproxy']['member_max_connections']} check"
end

haproxy_lb "#{node['haproxy']['mode']}" do
  type 'frontend'
  params({
    'maxconn' => node['haproxy']['frontend_max_connections'],
    'bind' => "#{node['haproxy']['incoming_address']}:#{node['haproxy']['incoming_port']}",
    'default_backend' => "servers-#{node['haproxy']['mode']}"
  })
end

haproxy_lb "servers-#{node['haproxy']['mode']}" do
  type 'backend'
  mode node['haproxy']['mode']
  servers servers
  params pool
end

if node['haproxy']['enable_ssl']
  pool = ["option ssl-hello-chk"]
  pool << ["options httpchk #{node['haproxy']['ssl_httpchk']}"] if node['haproxy']['ssl_httpchk']

  servers = node['haproxy']['pool_members'].uniq.map do |s|
    "#{s[:hostname]} #{s[:ipaddress]}:#{node['haproxy']['ssl_member_port']} weight 1 maxconn #{node['haproxy']['member_max_connections']} check"
  end

  haproxy_lb "servers-#{node['haproxy']['mode']}" do
    type 'backend'
    mode node['haproxy']['mode']
    servers servers
    params pool
  end
end

haproxy_config "Create haproxy.cfg" do
  notifies :restart, "service[haproxy]", :delayed
end
