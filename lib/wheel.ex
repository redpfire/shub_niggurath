
require Logger

defmodule Wheel.Pkg do
    defstruct class: nil, name: "", commands: []
    @callback init() :: {:ok}

    def register!(class, name) do
        pkg = %Wheel.Pkg{class: class, name: name}
        Logger.info("Registering #{name}")
        send :wheel, {:register, pkg}
    end

    def register_cmd!(class, name, callback) do
        send :wheel, {:get_class, class, self()}
        receive do 
            {:ok, pkg} ->
                c = %Command{name: name, fun: callback}
                send :commands, {:register, c}
                Logger.info("Registering command #{name} for pkg #{pkg.name}")
                npkg = %Wheel.Pkg{pkg | commands: pkg.commands ++ [c]}
                send :wheel, {:update_pkg, pkg, npkg}
                {:ok}
            {:error, :notfound} ->
                raise "Class not found"
        end
    end

    def equals?(a,b) do
        if a.class == b.class and a.name == b.name and a.commands == b.commands do
            true
        else
            false
        end
    end

    defp drop_(arr,pkg,o,len,n) when n < len do
        elem = Enum.at(arr,n)
        o = if !equals?(elem, pkg) do
            o ++ [elem]
        else
            o
        end
        drop_(arr,pkg,o,len,n+1)
    end

    defp drop_(arr,pkg,o,len,n) when n >= len do
        o
    end

    def drop(arr, pkg) do
        drop_(arr,pkg,[],length(arr),0)
    end

    def join_names_(pkgs, n, o, len) when n < len do
      el = Enum.at(pkgs, n)
      o =
        if o != "" do
          "#{o}, #{el.name}"
        else
          "#{el.name}"
        end
      join_names_(pkgs,n+1,o,len)
    end

    def join_names_(pkgs,n,o,len) when n >= len do
      o
    end

    def join_names(pkgs) do
      join_names_(pkgs, 0, "", length(pkgs))
    end
end

defmodule Wheel do
    def start() do
        if Process.whereis(:wheel) == nil do
            p = spawn fn -> roll(%{
                pkgs: []
            }) end
            Process.register(p, :wheel)
            # process all packages
            process_pkgs()
        end
    end

    defp process_pkgs() do
        pkgs = File.ls!("Wheel/pkgs")
        Enum.each(pkgs, fn x ->
            filename = "Wheel/pkgs/#{x}/main.ex"
            load!(filename)
        end)
    end

    def load!(filename) do
        [{comp, _}] = Code.load_file(filename)
        comp.init()
    end

    defp find_class_(arr, class, o, len, n) when n < len do
        elem = Enum.at(arr, n)
        if elem.class == class do
            find_class_(arr, class, elem, len, len)
        else
            find_class_(arr, class, o, len, n+1)
        end
    end

    defp find_class_(arr, class, o, len, n) when n >= len do
        o
    end

    defp find_class(arr, class) do
        find_class_(arr, class, nil, length(arr), 0)
    end

    defp roll(map) do
        receive do
            {:register, pkg} ->
                npkgs = map[:pkgs] ++ [pkg]
                map = %{map | pkgs: npkgs}
                roll(map)
            {:get_packages, pid} ->
                send pid, {:ok, map[:pkgs]}
                roll(map)
            {:get_class, class, pid} ->
                pkg_ = find_class(map[:pkgs], class)
                if pkg_ != nil do
                    send pid, {:ok, pkg_}
                else
                    send pid, {:error, :notfound}
                end
                roll(map)
            {:update_pkg, opkg, npkg} ->
                op = Wheel.Pkg.drop(map[:pkgs], opkg)
                op = op ++ [npkg]
                map = %{map | pkgs: op}
                roll(map)
            {:inspect, pid} ->
                if Process.whereis(:console) == pid do
                    IO.puts("\r#{inspect map[:pkgs]}")
                end
                roll(map)
        end
    end
end
