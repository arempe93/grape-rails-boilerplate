# frozen_string_literal: true

require 'io/console'

namespace :setup do
  task :env do
    begin
      print "Enter your mysql username (blank for root):"
      mysql_user = STDIN.gets.chomp

      print "Enter your mysql password (blank for none):"
      mysql_pass = STDIN.noecho(&:gets).chomp

      env = <<~SH
        export REDISTOGO_URL=redis://localhost:6379/1

        export SIDEKIQ_WEB_USER=sidekiq
        export SIDEKIQ_WEB_PASS=sidekiq

        export MYSQL_USER=#{mysql_user.empty? ? 'root' : mysql_user}
        export MYSQL_PASS=#{mysql_pass}
      SH

      File.open(Rails.root.join('.env'), 'w') { |f| f.write(env) }

      puts "\nEnvironment config created"

    rescue StandardError, Interrupt
      puts "\n"
      abort
    end
  end
end

task setup: %w[setup:env db:create precommit:install]
