
require Logger
require DiscordEx

defmodule Command do
    @enforce_keys [:name, :fun]
    defstruct name: "", fun: nil

    def fetch(map, field) do
        Map.fetch(map, field)
    end

    def is_command(a = %Command{}) do
        true
    end
    def is_command(a) do
        false
    end
end

defmodule Commands do
    def start() do
        p = spawn_link fn -> roll(%{
            commands: []
        }) end
        Process.register(p, :commands)
        Wheel.start()
        {:ok}
    end

    defp remcmd(cmd, arr) do
        c = []
        Enum.each(arr, fn x -> if x != cmd do c ++ [x] end end)
        c
    end

    defp find_(arr, o, name, len, n) when n < len do
        a = Enum.at(arr, n)
        if a[:name] == name do
            o = a
            find_(arr, o, name, len, len) 
        else
            find_(arr, o, name, len, n+1)
        end
    end

    defp find_(arr, o, name, len, n) when n >= len do
        o
    end

    defp find(arr, name) do
        find_(arr, nil, name, length(arr), 0)
    end

    defp populate() do
        fun = fn args,c_map -> 
            str = 
              if length(args) > 1 do
                a_ = Enum.join(args, " ")
                String.replace(a_, "#{hd(args)} ", "")
              else
                ""
              end
            DexHelper.send_message(c_map, c_map.channel, str)
        end
        c = %Command{name: "test", fun: fun}
        send self(), {:register, c}

        fun = fn args,c_map ->
            str =
            if length(args) > 1 do
                str = Enum.join(args, " ")
                String.replace(str, "#{hd(args)} ", "")
            else
                ""
            end
            if c_map.author["id"] == 197463298151677953 do
                {x, _} = Code.eval_string(str, [args: args, c_map: c_map], __ENV__)
                author = %RichEmbedAuthor{name: "Eval output"}
                f0 = %RichEmbedField{name: ":inbox_tray: Input:", value: "```elixir\n#{str}\n```"}
                f1 = %RichEmbedField{name: ":outbox_tray: Output:", value: "```elixir\n#{inspect x}\n```"}
                footer = %RichEmbedFooter{text: "Elixir"}
                re = %RichEmbed{color: {132, 21, 88}, fields: [f0,f1], footer: footer, author: author}
                RichEmbed.send(re, c_map, c_map.channel)
            end
        end
        c = %Command{name: "eval", fun: fun}
        send self(), {:register, c}

        fun = fn args,c_map ->
            id = c_map.author["id"]
            send :selfroles, {:get_user, id, self()}
            receive do
                {:ok, user} ->
                    if Enum.empty?(user.roles) do
                        DexHelper.send_message(c_map, c_map.channel, "Your don't have any roles!")
                    else
                        roles_str = Selfroles.User.roles_to_string(user.roles)
                        DexHelper.send_message(c_map, c_map.channel, "Your roles: #{roles_str}")
                    end
                {:error, :notfound} ->
                    u = %Selfroles.User{id: id}
                    send :selfroles, {:register_user, u, self()}
                    receive do x -> x end
                    DexHelper.send_message(c_map, c_map.channel, "Your don't have any roles!")
            end
        end
        c = %Command{name: "roles", fun: fun}
        send self(), {:register, c}

        fun = fn args,c_map ->
            id = c_map.author["id"]
            send :selfroles, {:get_user, id, self()}
            u = receive do
                {:ok, user} ->
                    user
                {:error, :notfound} ->
                    u = %Selfroles.User{id: id}
                    send :selfroles, {:register_user, u, self()}
                    receive do x -> x end
                    u
            end
            send :selfroles, {:get_role, Enum.at(args, 1), self()}
            receive do
                {:ok, role} ->
                    send :selfroles, {:join, u, role, self()}
                    receive do
                        {:ok} ->
                            DexHelper.send_message(c_map, c_map.channel, "Welcome aboard of #{role.name}!")
                        {:error, :hasrole} ->
                            DexHelper.send_message(c_map, c_map.channel, "You already have that role!")
                    end
                {:error, :notfound} ->
                    DexHelper.send_message(c_map, c_map.channel, "No such role!")
            end
        end
        c = %Command{name: "join_role", fun: fun}
        send self(), {:register, c}

        fun = fn args, c_map ->
            id = c_map.author["id"]
            send :selfroles, {:get_user, id, self()}
            u = receive do
                {:ok, user} ->
                    user
                {:error, :notfound} ->
                    DexHelper.send_message(c_map, c_map.channel, "You don't have any roles!")
                    nil
            end
            if u != nil do
                send :selfroles, {:get_role, Enum.at(args, 1), self()}
                receive do
                    {:ok, role} ->
                        send :selfroles, {:part, u, role, self()}
                        receive do
                            {:ok} -> 
                                DexHelper.send_message(c_map, c_map.channel, "You part #{role.name}.")
                            {:error, :hasnorole} ->
                                DexHelper.send_message(c_map, c_map.channel, "You don't have that role!")
                        end
                    {:error, :notfound} ->
                        DexHelper.send_message(c_map, c_map.channel, "No such role!")
                end
            end
        end
        c = %Command{name: "part_role", fun: fun}
        send self(), {:register, c}
        c = %Command{name: "leave_role", fun: fun}
        send self(), {:register, c}

        fun = fn args, c_map ->
          send :wheel, {:get_packages, self()}
          receive do
            {:ok,pkgs} ->
              str = Wheel.Pkg.join_names(pkgs)
              DexHelper.send_message(c_map, c_map.channel, "Modules:\n```#{str}```")
          end
        end
        c = %Command{name: "modules", fun: fun}
        send self(), {:register, c}
    end

    def roll(map) do
        receive do
            {:find, name, pid} ->
                f = find(map[:commands], name)
                if f != nil do
                    send pid, {:cmd, f}
                else
                    send pid, {:error, :notfound}
                end
                roll(map)
            {:unregister, cmd} ->
                map = if Command.is_command(cmd) do
                    cmds = remcmd(cmd, map[:commands])
                    %{map | commands: cmds}
                else
                  map
                end
                roll(map)
            {:register, cmd} ->
                map = if Command.is_command(cmd) do
                    cmds = map[:commands] ++ [cmd]
                    %{map | commands: cmds}
                else
                  map
                end
                roll(map)
            {:populate, pid} ->
                if Process.whereis(:main) == pid do
                    Logger.info("Populating commands.")
                    populate()
                end
                roll(map)
            {:get_all, pid} ->
                if Process.whereis(:console) == pid do
                    IO.puts(inspect(map[:commands]))
                else
                    send pid, {:ok, map[:commands]}
                end
                roll(map)
        end
    end
end
