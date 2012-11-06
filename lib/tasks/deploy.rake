class Deployer
  attr_accessor :env

  def initialize(env)
    @env = env
  end

  def deploy!
    system "heroku maintenance:on --remote #{env}"
    system "git push #{env} master"
    system "heroku run rake db:migrate --remote #{env}"
    system "heroku maintenance:off --remote #{env}"
    system "heroku restart --remote #{env}"
  end
end

namespace :deploy do
  desc "Push master to staging remote, then migrate"
  task(:staging) { Deployer.new('staging').deploy! }

  desc "Push master to production remote, then migrate"
  task(:production) { Deployer.new('production').deploy! }
end

desc "Alias for deploy:staging"
task deploy: 'deploy:staging'
