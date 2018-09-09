
require Logger
require DiscordEx

defmodule Bot do
  use Application
  defp start_console(bot) do
    Process.register(self(), :console)
    console(bot)
  end
  defp console(bot) do
    v = IO.gets("> ")
    v = Regex.replace(~r/\n/, v, "")
    {x, x2} = 
    try do
      Code.eval_string(v, [bot: bot], __ENV__)
    rescue
      x -> {x, :error}
    end
    case x2 do
      :error ->
        Logger.error(inspect x)
      _ ->
        IO.puts("\r#{inspect(x)}")
    end
    console(bot)
  end
  def start(argc, argv) do
    Process.register(self(), :main)
    {:ok} = Vault.start()
    send :vault, {:get, self()}
    receive do
      {:token, token} ->
        {:ok, bot} = DiscordEx.Client.start_link(%{
        token: token,
        handler: Event_handler
        })
        spawn_link fn -> start_console(bot) end
        {:ok} = Commands.start()
        send :commands, {:populate, self()}
        Sandbox.start(bot)
    end
    receive do
     x ->
      x
    end
  end
end
