class RaceEventController < ApplicationController
  def index
    @is_desktop = is_desktop
  end
end
