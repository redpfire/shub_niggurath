require Logger
require DiscordEx
alias DiscordEx.Client.Helpers.MessageHelper
alias DiscordEx.RestClient.Resources.User

defmodule Sandbox do
    def start(bot) do
        p = spawn fn -> roll(%{
            bot: bot,
            prefix: "xd;"
        }) end
        Selfroles.Spinlock.start()
        Process.register(p, :sandbox)
        {:ok, p}
    end
    defp traverse(cmd_fun, args, e_map) do
        try do
            cmd_fun.(args,e_map)
        rescue
            x -> 
                DexHelper.react(e_map, "😕", e_map.channel, e_map.payload.data["id"])
                Logger.error(x)
        end
    end
    defp roll(map) do
        receive do
            {:event, e, payload, state} ->
                e_map = %{event: e, payload: payload, state: state}
                case e do
                    :message_create ->
                        author = payload.data["author"]
                        channel = payload.data["channel_id"]
                        e_map = %{event: e, payload: payload, state: state, author: author, channel: channel}
                        #Logger.info("#{inspect payload}")
                        if String.starts_with?(payload.data["content"], map[:prefix]) do
                            text = String.replace(payload.data["content"], map[:prefix], "")
                            args = String.split(text, " ")
                            Logger.info("#{author["username"]} issued a command #{Enum.at(args, 0)}")
                            send :commands, {:find, Enum.at(args, 0), self()}
                            receive do
                                {:error, :notfound} ->
                                    Logger.info("Command not found.")
                                    DexHelper.react(e_map, "✨", e_map.channel, e_map.payload.data["id"])
                                {:cmd, f} ->
                                    spawn fn -> traverse(f[:fun], args, e_map) end
                            end
                        end
                    _ ->
                        roll(map)
                    # _ ->
                    #     Logger.info("Sandbox got event #{e}")
                end
        end
        roll(map)
    end
end