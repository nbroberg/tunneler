Tunneler
=========

Tunneler is a Ruby command line interface for multi-hop SSH tunneling.

  - SCP files through a bastion host
  - Execute remote commands through a bastion host
  - SSH through a bastion host using native terminal

Version
----

0.0.1

Installation
--------------

```sh
gem install tunneler
```

Example Command-Line Usage
--------------

```sh
tunneler --bastion-host 150.1.2.3 --destination-host 151.2.3.4 ssh
tunneler --bastion-host 150.1.2.3 --destination-host 151.2.3.4 scp local_file destination_file
tunneler --bastion-host 150.1.2.3 -d 151.2.3.4 execute 'whoami'
```

Example Gem Usage
--------------

```ruby
require "tunneler"

# Create SSH tunnel
tunnel = Tunneler::SshTunnel.new(bastion_user, bastion_host, {:keys => [bastion_key]})

# Establish remote connection
destination_host_connection = tunnel.remote(destination_user, destination_host, {:keys => [destination_key]})

# Upload file to destination host via tunnel
destination_host_connection.scp(local_file_path, destination_file_path)

# Execute common on destination host via tunnel
response = destination_host_connection.ssh(command)
```


License
----

MIT
