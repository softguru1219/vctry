CarrierWave.configure do |config|
  config.root = Rails.root.join('tmp')
  config.cache_dir = 'carrierwave'
  
  config.fog_provider = 'fog/aws'                        # required
  config.fog_credentials = {
    provider:              'AWS',                        # required
    aws_access_key_id:     'AKIAJQX6K2BAUD5TK5JA',                        # required
    aws_secret_access_key: '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',                        # required
    region:                'us-east-2',                  # optional, defaults to 'us-east-2'
  }
  if Rails.env.production?
    config.fog_directory  = "vctry-production"
  elsif Rails.env.staging?
    config.fog_directory  = "vctry-staging"
  end
  config.fog_public     = true                                               
  config.fog_attributes = { cache_control: "public, max-age=#{365.days.to_i}" }
  config.storage = :fog

  config.ignore_integrity_errors = false
  config.ignore_processing_errors = false
  config.ignore_download_errors = false

  # For testing, upload files to local `tmp` folder.
  if Rails.env.development?
    config.root = Rails.root.join('public')
    config.storage = :file
    #config.root = "#{Rails.root}/tmp"
    config.asset_host = 'http://192.168.180.128:3000/'
  end
end