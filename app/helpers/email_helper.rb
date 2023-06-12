module EmailHelper
  def email_image_tag(image, **options)
    attachments[image] = File.read("#{Rails.root}/app/assets/images/home/#{image}")
    image_tag attachments[image].url, **options
  end
end