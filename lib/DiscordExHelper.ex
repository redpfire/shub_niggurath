
require DiscordEx
alias DiscordEx.RestClient.Resources.User
alias DiscordEx.RestClient.Resources.Channel

defmodule DexHelper do
    def react(c_map, emote, cid, mid) do
        DiscordEx.RestClient.resource(c_map.state[:rest_client], :put, "channels/#{cid}/messages/#{mid}/reactions/#{emote}/@me", %{})
    end
    def send_message(c_map, cid, msg) do
        Channel.send_message(c_map.state[:rest_client], cid, %{content: msg})
    end
end