
require Logger

defmodule TestPkg do
    alias Wheel.Pkg
    @behaviour Wheel.Pkg

    @spec cmd(list, map) :: {:ok}
    def cmd(args, c_map) do
        DexHelper.send_message(c_map, c_map.channel, "Boop")
        {:ok}
    end

    def init() do
        Pkg.register!(TestPkg, "test_mod")
        Pkg.register_cmd!(TestPkg, "lol", fn a,b -> cmd(a,b) end)
    end
end
