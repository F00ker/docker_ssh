#!/usr/bin/ruby
# -*- coding: utf-8 -*- #
###################################
########### Steffy FORT ###########
##### https://github.com/fe80 #####
###################################

# All require
require 'fileutils'

# Define info, warning, error
# Call with printf
cyan    = "\e[0;36m"
orange  = "\e[0;33m"
red     = "\e[0;31m"
reset   = "\e[0m"
info    = "[#{cyan}info#{reset}]"
warning = "[#{orange}warning#{reset}]"
error   = "[#{red}error#{reset}]"


# Check if argv exist
if ARGV.length != 3
  puts "#{error} Error, bad argument please read README"
  Kernel.exit(1)
end


# Default variable
curr_ip   = ARGV[0].split(" ").first
cmd       = ARGV[1]
user      = ARGV[2]
c_user    = "container_user"
root_dir  = '/srv/docker-ssh'
uid       = '10000'
gid       = nil
conf      = "#{root_dir}/conf"
params    = "#{conf}/user.conf"
d_bashrc  = "#{conf}/bashrc_default"
d_bashpf  = "#{conf}/bash_profile_default"
index     = 1
home_user = "#{root_dir}/users/#{user}"
d_repo    = nil

# Check if user env exist
if !File.exist?(home_user)
	FileUtils.mkdir_p home_user, :mode => 0775
	FileUtils.chown_R uid, gid, home_user
elsif !File.directory?(home_user)
	puts "#{error} Home is not a directory."
	Kernel.exit(1)
end

if File.exist?(d_bashrc)
  if !File.exist?("#{home_user}/.bashrc")
    FileUtils.cp d_bashrc, "#{home_user}/.bashrc"
    FileUtils.chown uid, gid, "#{home_user}/.bashrc"
  end
else
  puts "#{warning} Default bashc doesn\'t exist."
end

if File.exist?(d_bashpf)
  if !File.exist?("#{home_user}/.bash_profile")
    FileUtils.cp d_bashpf, "#{home_user}/.bash_profile"
    FileUtils.chown uid, gid, "#{home_user}/.bash_profile"
  end
else
  puts "#{warning} Default bash_profile doesn\'t exist."
end

if !File.exist?(g_bashpf)
  puts "#{error} Global bash_profile doesn\'t exist. "
  Kernel.exit(1)
end


# Check if params fil exist
if !File.exist?(params)
  puts "#{error} Params users doesn't exist"
  Kenrel.exit(1)
end


# Recovery params user
File.open(params, 'r') do |in_params|
  in_params.each_line do |l_params|
    if l_params =~  /#{user}:(.*):(.*)/
      @tag          = $1
      @forward_dir  = $2
    end
  end
end


# Check if scp command
if cmd =~ /^scp -t (.*)/
  scp_dir = File.join($1, "")

  @forward_dir.split(',').each do |l_dir|
    l0_dir  = File.join(l_dir, "")
    if scp_dir =~ /^#{l0_dir}.*/
      system( "sudo -u \\##{uid} #{cmd}" )
      Kernel.exit(0)
    end
  end
  puts "#{error} #{scp_dir} Permission denied"
  Kernel.exit(1)
end

# Show if container already exist
docker_ps = `docker ps`
d_arr     = Array.new

docker_ps.each_line do |l_ps|
  if l_ps =~ /.*ssh_#{user}_#{curr_ip}_(\d)+$/
    d_arr.push($1)
  end
end

if !d_arr.empty?
  d_arr.sort.each do |l_arr|
    if index.eql? l_arr.to_i
      index += 1
    else
      break
    end
  end
end

# Defined docker argument
container = "#{d_repo}/#{@tag}:ssh"
@volume   = ""

@forward_dir.split(',').each do |l_dir|
  @volume << "-v #{l_dir}:#{l_dir} "
end

# Run container
if cmd.empty?
   run_cmd = "docker run --rm=true " \
            "-v #{home_user}:/home/#{c_user} " \
            "#{@volume} " \
            "--net=host " \
            "--name=ssh_#{user}_#{curr_ip}_#{index} " \
            "#{container} " \
            "/bin/bash"
else
  run_cmd = "docker run -it --rm=true " \
            "-v #{home_user}:/home/#{c_user} " \
            "#{@volume} " \
            "--net=host " \
            "--name=ssh_#{user}_#{curr_ip}_#{index} " \
            "#{container} " \
            "/bin/bash -c \"#{cmd}\""
end

system(run_cmd)
