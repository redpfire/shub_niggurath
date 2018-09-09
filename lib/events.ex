
require Logger
require DiscordEx

defmodule Event_handler do
    def handle_event({event, p}, state) do
        if Process.whereis(:sandbox) != nil do
            send :sandbox, {:event, event, p, state}
        end
        {:ok, state}
    end
end