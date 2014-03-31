Capistrano::Configuration.instance(:must_exist).load do |configuration|

  _cset :foreman_upstart_path, "/etc/init/sites"
  _cset :foreman_options, {}
  _cset :foreman_use_binstubs, false
  _cset :foreman_cmd, 'bundle exec foreman'
  _cset :foreman_roles, [:app]

  namespace :foreman do
    desc "Export the Procfile to Ubuntu's upstart scripts"
    task :export, roles: foreman_roles do
      cmd = foreman_use_binstubs ? 'bin/foreman' : foreman_cmd
      run "if [[ -d #{foreman_upstart_path} ]]; then mkdir -p #{foreman_upstart_path}; fi"
      run "cd #{current_path} && #{cmd} export upstart #{foreman_upstart_path} #{format(options)}"
      try_sudo "initctl reload-configuration"
    end

    desc "Start the application services"
    task :start, roles: foreman_roles do
      try_sudo "initctl start #{options[:app]}"
    end

    desc "Stop the application services"
    task :stop, roles: foreman_roles do
      try_sudo "initctl stop #{options[:app]} || echo 'Jobs not running for #{options[:app]}'"
    end

    desc "Restart the application services"
    task :restart, roles: foreman_roles do
      stop
      start
    end

    def options
      {
        app: application,
        log: "#{shared_path}/log",
        user: user
      }.merge foreman_options
    end

    def format opts
      opts.map { |opt, value| "--#{opt}=#{value}" }.join " "
    end
  end

end
