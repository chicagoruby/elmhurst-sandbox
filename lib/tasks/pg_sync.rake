class PgSyncer
  attr_accessor :capture_url

  def initialize(env)
    @capture_url = capture! env
  end

  def local_sync!
    system "curl -o capture.dump '#{capture_url}'"
    system "pg_restore --verbose --clean --no-acl --no-owner -U #{local_username} -d #{local_db} capture.dump"
    system 'rm -f capture.dump'
  end

  def stage_sync!
    system "heroku pgbackups:restore DATABASE '#{capture_url}' --remote staging"
  end

  private

  def capture!(env)
    system "heroku pgbackups:capture --remote #{env}"
    system "heroku pgbackups:url --remote #{env}"
  end

  def development_config
    @development_config ||= YAML.load(Rails.root.join('config', 'database.yml').read)['development']
  end

  def local_username
    development_config['username']
  end

  def local_db
    development_config['database']
  end
end

namespace :pg_sync do
  desc "Capture a backup of production and restore to your local database"
  task(:production_to_local) { PgSyncer.new('production').local_sync! }

  desc "Capture a backup of production and restore to your staging database"
  task(:production_to_staging) { PgSyncer.new('production').stage_sync! }

  desc "Capture a backup of staging and restore to your local database"
  task(:staging_to_local) { PgSyncer.new('staging').local_sync! }
end
