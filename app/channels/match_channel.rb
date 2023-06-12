class MatchChannel < ApplicationCable::Channel
  def subscribed
    stream_from "room_channel_#{params[:roomId]}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def receive(data)
    p data
    # ActionCable.server.broadcast "room_channel_#{message.roomId}", message: data.body
  end
end