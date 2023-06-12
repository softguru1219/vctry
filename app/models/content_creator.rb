class ContentCreator < ApplicationRecord
  # translates :subtitle, :description
  mount_uploader :logo, CreatorLogoUploader


  def self.current_creator_code(params)
    if params[:code].present?
      ContentCreator.find_by('lower(code) = ?', params[:code].downcase)
    end
  end
end
