<h1>nagios-plugins</h1>
<p><a href="https://www.gnu.org/licenses/gpl.html"> <img src="https://img.shields.io/badge/license-GNU--3-blue.svg?style=flat" alt="License" /> </a></p>
<p>This repository contains various scripts than I wrote for <a href="https://github.com/NagiosEnterprises/nagioscore">Nagios Core</a>.
Many of them were written from small to medium monitoring environments. And are based in three main concepts:</p>
<ul>
<li><strong>Avoid to install</strong> anything on the remote client side.</li>
<li>Focus on the Linux enviroments.</li>
<li>Use <code>ssh</code> like an authentication method.</li>
</ul>
<h3>Brief Description</h3>
<p>The reason for this project is <em>&quot;based on my experienced&quot;</em> how <strong>improve</strong> the way to do <strong><a href="https://github.com/NagiosEnterprises/nagioscore">Nagios Core</a> active checks</strong>. The concept is not complicated just:</p>
<ol>
<li><strong>Login</strong> into the remote machine.</li>
<li><strong>Execute</strong> the check command.</li>
<li><strong>Bring</strong> the results to the local server.</li>
<li><strong>Pharse and display</strong> the results.</li>
</ol>
<h2>Installation</h2>
<ol>
<li>
<p><strong>You need</strong></p>
<p><strong>Clone and copy</strong> the scripts to your nagios libexec folder:
<code>bash
	host$ git clone git@github.com:eddimas/nagios-plugins.git
	host$ cd nagios-plugins
	host$ cp ./* /usr/local/nagios/libexec/</code></p>
</li>
<li>
<p>The <strong>remote client</strong> needs:</p>
<p><em>Obviously</em> an <strong>efective user with ssh login grant</strong> and preferably set-up the <code>ssh_keys</code> interchange <em>(<a href="http://www.thegeekstuff.com/2008/11/3-steps-to-perform-ssh-login-without-password-using-ssh-keygen-ssh-copy-id/">perform ssh login without password</a>)</em>. </p>
</li>
<li>
<p>Your <strong>Nagios instance</strong> needs:</p>
<p>Set-up your remote host:
<code>bash
nagios$ vi /usr/local/nagios/etc/objects/hosts.cfg
	define host{
	    use         generic-host	 	; Inherit default values from a template
	    host_name   remotehost      ; The name we're giving to this host
	    alias		Some Remote Host	  ; A longer name associated with the host
	    address     192.168.1.50		; IP address of the host
	    hostgroups  allhosts        ; Host groups this host is associated with
	}</code></p>
<p>Add the new command:
<code>bash
nagios$ vi /usr/local/nagios/etc/objects/commands.cfg
	define command{
	    name	      check_disk
	    command_name	check_disk
	    command_line	$USER1$/check_disk.sh -l username -I $HOSTADDRESS$ -w $ARG1$ -c $ARG2$
	}</code></p>
<p>Create the new service:
<code>bash
nagios$ vi /usr/local/nagios/etc/objects/services.cfg
	define service{
	    use                 generic-service		; Inherit default values from a template
	    host_name           remotehost
	    service_description Check Remote Server Disks
	    check_command       check_disk
	}</code></p>
</li>
</ol>
<h3>Todo's</h3>
<ul>
<li>Write Tests</li>
<li>Rethink Github Save</li>
<li>Add Code Comments</li>
<li>Add Night Mode</li>
</ul>
<h2>Contributing</h2>
<p>If you would like help implementing a new tracker or adding any additional enrichment please feel free to do it! just:</p>
<ol>
<li>Fork it.</li>
<li>Create your feature branch (<code>git checkout -b fixing-blah</code>).</li>
<li>Commit your changes (<code>git commit -am 'Fixed blah'</code>).</li>
<li>Push to the branch (<code>git push origin fixing-blah</code>).</li>
<li>Create a new pull request.</li>
</ol>
<p>Do not update changelog or attempt to change version.</p>
<h3>Copyright and license</h3>
<p>Copyright (C) 2015  Eduardo Dimas</p>
<p>This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.</p>
<p>This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.</p>
<p>You should have received a copy of the GNU General Public License along with this program.  If not, see <a href="https://www.gnu.org/licenses/gpl.html">license</a>.</p>
