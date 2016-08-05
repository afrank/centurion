require 'json'

task :parse_marathon => 'parse_marathon:default'

namespace :parse_marathon do
  task :default do
    env = fetch(:environment,nil)
    registry = fetch(:registry,nil)
    image = fetch(:image,nil)
    new_image = image.sub(/datanerd.us/,'cf-registry.nr-ops.net')
    team = image.split('/')[1]
    status_endpoint = fetch(:status_endpoint,nil)
    memory = fetch(:memory,0) / 1000 / 1000
    ports = fetch(:port_bindings,[]).map {|port| {'containerPort' => port.host_port, 'hostPort' => 0, 'protocol' => 'tcp', 'labels' => {} } }
    env_vars = fetch(:env_vars,{})
    hosts = fetch(:hosts,nil)
    project = fetch(:project,nil)
    healthchecks = []
    if status_endpoint != nil then
      healthchecks = [{"path" => status_endpoint, "protocol" => "HTTP", "portIndex" => 0, "gracePeriodSeconds" => 300, "intervalSeconds" => 60, "timeoutSeconds" => 20, "maxConsecutiveFailures" => 3, "ignoreHttp1xx" => false }]
    end
    marathon_hash = {
      "id" => "/" + project,
      "cmd" => nil,
      "cpus" => 1,
      "mem" => memory,
      "disk" => 0,
      "instances" => hosts.length,
      "container" => {
        "type" => "DOCKER",
        "volumes" => [],
        "docker" => {
          "image" => new_image,
          "network" => "BRIDGE",
          "portMappings" => ports,
          "privileged" => false,
          "parameters" => [
            {
              "key" => "label",
              "value" => "ServiceName=" + project
            },
            {
              "key" => "label",
              "value" => "TeamName=" + team
            },
            {
              "key" => "label",
              "value" => "Environment=" + env
            }
          ],
          "forcePullImage" => false
        },
      },
      "env" => env_vars,
      "healthchecks" => healthchecks
    }
    # puts marathon_hash.to_json
    puts JSON.pretty_generate(marathon_hash)
  end
end
