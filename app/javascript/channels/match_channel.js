import consumer from "./consumer"

window.connectMatch = function (matchId) {
  consumer.subscriptions.create({ channel: "MatchChannel", roomId: matchId }, {
    connected() {
      // Called when the subscription is ready for use on the server
    },

    disconnected() {
      // Called when the subscription has been terminated by the server
    },

    received(receive_data) {
      // Called when there's incoming data on the websocket for this channel
      if (receive_data.message.action == "check_in_finished") {
        Turbolinks.visit(receive_data.message.url);
      } else if(receive_data.message.action == "submitted the score") {
        Turbolinks.visit(receive_data.message.url);
      } else if(receive_data.message.action == "confirmed the score") {
        Turbolinks.visit(receive_data.message.url);
      }

      if (receive_data.message.action == 'found the completed match') {
        location.reload();
      }

      if (receive_data.message.action == 'Match data is updated') {
        Turbolinks.visit(receive_data.message.url);
      }
    }
  });
}


window.connectTournament = function (tournamentId) {
  consumer.subscriptions.create({ channel: "MatchChannel", roomId: tournamentId }, {
    connected() {
      // Called when the subscription is ready for use on the server
    },

    disconnected() {
      // Called when the subscription has been terminated by the server
    },

    received(receive_data) {

      if (receive_data.message.action == 'match_ready') {
        var current_user = $("#current_user_id").val();
        if (current_user.length > 0) {
          if (receive_data.message.players.includes(parseInt(current_user))){
            Turbolinks.visit(receive_data.message.url);
          }
        }
      }

      // Called when there's incoming data on the websocket for this channel
      if (receive_data.message.action == 'Standing data is updated') {
        location.reload();
      }

      if (receive_data.message.action == 'Stage data is updated') {
        location.reload();
      }
    }
  });
}