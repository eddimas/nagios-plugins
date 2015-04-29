# nagios-plugins
[ ![License] [license-image] ] [license]

This repository contains various scripts than I wrote for [Nagios Core].
Many of them were written from small to medium monitoring environments. And are based in three main concepts:

* **Avoid to install** anything on the remote client side.
* Focus on the Linux enviroments.
* Use `ssh` like an authentication method.

### Brief Description

The reason for this project is *"based on my experienced"* how **improve** the way to do **[Nagios Core] active checks**. The concept is not complicated just:

1. **Login** into the remote machine.
2. **Execute** the check command.
3. **Bring** the results to the local server.
4. **Pharse and display** the results.

## Installation

1. **You need**
	
	**Clone and copy** the scripts to your nagios libexec folder:
	```bash
		host$ git clone git@github.com:eddimas/nagios-plugins.git
		host$ cd nagios-plugins
		host$ cp ./* /usr/local/nagios/libexec/
	```

2. The **remote client** needs:

	*Obviously* an **efective user with ssh login grant** and preferably set-up the `ssh_keys` interchange *([perform ssh login without password])*. 

3. Your **Nagios instance** needs:

	 Set-up your remote host:
	```bash
	nagios$ vi /usr/local/nagios/etc/objects/hosts.cfg
    	define host{
    	    use         generic-host	 	; Inherit default values from a template
		    host_name   remotehost      ; The name we're giving to this host
		    alias		Some Remote Host	  ; A longer name associated with the host
		    address     192.168.1.50		; IP address of the host
		    hostgroups  allhosts        ; Host groups this host is associated with
		}
	```

	Add the new command:
	``` bash
	nagios$ vi /usr/local/nagios/etc/objects/commands.cfg
    	define command{
    	    name	      check_disk
    	    command_name	check_disk
    	    command_line	$USER1$/check_disk.sh -l username -I $HOSTADDRESS$ -w $ARG1$ -c $ARG2$
    	}
	```

	Create the new service:
	``` bash
	nagios$ vi /usr/local/nagios/etc/objects/services.cfg
    	define service{
    	    use                 generic-service		; Inherit default values from a template
    	    host_name           remotehost
    	    service_description Check Remote Server Disks
    	    check_command       check_disk
    	}
	```

### Todo's

 - Write Tests
 - Rethink Github Save
 - Add Code Comments
 - Add Night Mode

## Contributing

If you would like help implementing a new tracker or adding any additional enrichment please feel free to do it! just:

1. Fork it.
2. Create your feature branch (`git checkout -b fixing-blah`).
3. Commit your changes (`git commit -am 'Fixed blah'`).
5. Push to the branch (`git push origin fixing-blah`).
6. Create a new pull request.

Do not update changelog or attempt to change version.

### Copyright and license

Copyright (C) 2015  Eduardo Dimas

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program.  If not, see [license].

[license-image]: https://img.shields.io/badge/license-GNU--3-blue.svg?style=flat
[license]: https://www.gnu.org/licenses/gpl.html
[Nagios]:https://github.com/NagiosEnterprises/nagioscore
[Nagios Core]:https://github.com/NagiosEnterprises/nagioscore
[perform ssh login without password]: http://www.thegeekstuff.com/2008/11/3-steps-to-perform-ssh-login-without-password-using-ssh-keygen-ssh-copy-id/