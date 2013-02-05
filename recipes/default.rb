oracle_filename = node[:oracle_xe][:oracle_install_filename]
symlinks = {
  '/sbin/insserv' => '/usr/lib/insserv/insserv',
  '/bin/awk' => '/usr/bin/awk'
}

execute 'copy oracle installation file' do
  command "cp #{node[:oracle_xe][:oracle_install_source]}/#{oracle_filename} /tmp/"
  creates "/tmp/#{oracle_filename}"
end

%w{alien bc libaio1 expect unixodbc chkconfig pmount}.each do | pkg |
  package pkg do
    action :install
  end
end

template '/tmp/configure_oracle.sh' do 
  source 'configure_oracle.sh.erb'
  mode 0755
  variables :http_port => node[:oracle_xe][:http_port], :listener_port => node[:oracle_xe][:listener_port], :sysdba_password => node[:oracle_xe][:sysdba_password]
end

group 'dba'

user 'oracle' do
  comment 'user for managing databases'
  gid 'dba'
  shell '/bin/bash'
  home '/home/oracle'
  supports :manage_home => true
end

symlinks.each do |to, from|
  execute "symlink from #{from} to #{to}" do
    command "ln -s #{from} #{to}"
    creates to
  end
end

execute 'create subsys' do
  command 'mkdir /var/lock/subsys'
  creates '/var/lock/subsys'
end

cookbook_file '/etc/sysctl.d/60-oracle.conf ' do
  action :create
  source 'oracle.conf'
  mode 644
end

cookbook_file '/sbin/chkconfig' do
  action :create
  source 'chkconfig'
  mode 755
end

execute 'install oracle' do
  user 'root'
  command "alien --scripts -i #{oracle_filename}"
  cwd '/tmp'
  action :run
  creates '/u01/app/oracle'
end

bash 'fix /dev/shm problem' do
  code %Q{
    umount /dev/shm
    rm /dev/shm -rf
    mkdir /dev/shm
    mount -t tmpfs shmfs -o size=2048m /dev/shm
    sysctl kernel.shmmax=1073741824 
  }
end

bash 'setup oracle user' do
  user 'oracle'
  cwd '/home/oracle'
  code %Q{
    echo "" >>./.profile
    echo '. /u01/app/oracle/product/11.2.0/xe/bin/oracle_env.sh' >>./.profile
    touch ./.user_created
  }
  creates '/home/oracle/.user_created'
end

execute 'configure_oracle' do
  command '/tmp/configure_oracle.sh'
  action :run
end