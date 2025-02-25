# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'net/http'
require 'json'

DIGITAL_OCEAN_TOKEN = ENV["DIGITAL_OCEAN_TOKEN"]
DROPLET_REGION = 'fra1'

unique_hostname = "webserver-#{Time.now.strftime('%Y%m%d%H%M')}"

# Function to get an existing reserved IP or create one
def get_or_create_reserved_ip()
  uri = URI("https://api.digitalocean.com/v2/reserved_ips")
  request = Net::HTTP::Get.new(uri)
  request["Authorization"] = "Bearer #{DIGITAL_OCEAN_TOKEN}"
  request["Content-Type"] = "application/json"

  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    http.request(request)
  end

  reserved_ips = JSON.parse(response.body)["reserved_ips"]

  reserved_ip = reserved_ips&.find { |ip| ip["region"]["slug"] == DROPLET_REGION }

  if reserved_ip
    puts "Using existing reserved IP: #{reserved_ip["ip"]}"
    return reserved_ip["ip"]
  else
    puts "Requesting a new reserved IP..."
    uri = URI("https://api.digitalocean.com/v2/reserved_ips")
    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{DIGITAL_OCEAN_TOKEN}"
    request["Content-Type"] = "application/json"
    request.body = { "region" => DROPLET_REGION }.to_json

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    reserved_ip = JSON.parse(response.body)["reserved_ip"]
    puts "New reserved IP created: #{reserved_ip["ip"]}"
    return reserved_ip["ip"]
  end
end

RESERVED_IP = get_or_create_reserved_ip()

Vagrant.configure("2") do |config|
  config.vm.box = 'digital_ocean'
  config.vm.box_url = "https://github.com/devopsgroup-io/vagrant-digitalocean/raw/master/box/digital_ocean.box"
  config.ssh.private_key_path = '~/.ssh/ga_ssh_key'

  config.vm.synced_folder "remote_files", "/minitwit", type: "rsync"
  config.vm.synced_folder ".", "/vagrant", type: "rsync"

  config.vm.define unique_hostname, primary: false do |server|
    server.vm.provider :digital_ocean do |provider|
      provider.ssh_key_name = ENV["SSH_KEY_NAME"]
      provider.token = DIGITAL_OCEAN_TOKEN
      provider.image = 'ubuntu-22-04-x64'
      provider.region = DROPLET_REGION
      provider.size = 's-1vcpu-2gb'
      provider.privatenetworking = true
      provider.tags = ["webserver"]
    end

    server.vm.hostname = unique_hostname

    server.vm.provision "shell", inline: 'echo "export DOCKER_USERNAME=' + "'" + ENV["DOCKER_USERNAME"] + "'" + '" >> ~/.bash_profile'
    server.vm.provision "shell", inline: 'echo "export DOCKER_PASSWORD=' + "'" + ENV["DOCKER_PASSWORD"] + "'" + '" >> ~/.bash_profile'
    server.vm.provision "shell", path: './start_vm.sh'

    server.vm.provision "shell", inline: <<-SHELL
      echo "Provisioning new droplet..."
      cd /vagrant 

      chmod +x reassign_reserved_ip.sh
      ./reassign_reserved_ip.sh "#{DIGITAL_OCEAN_TOKEN}" "#{unique_hostname}" "#{RESERVED_IP}"

      echo "================================================================="
      echo "=                            DONE                               ="
      echo "=   Your Sinatra app is running. Navigate in your browser to:   ="
      echo "=   http://#{RESERVED_IP}:5000                                  ="
      echo "================================================================="
    SHELL
  end
end
