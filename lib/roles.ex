
require Logger
require DiscordEx

defmodule Selfroles.User do
@enforce_keys [:id]
defstruct id: -1, roles: []
@type t :: %Selfroles.User{}

    @spec join_role(Selfroles.User.t, Selfroles.Role.t) :: Selfroles.User.t
    def join_role(user, role) do
        nr = user.roles ++ [role]
        %Selfroles.User{user | roles: nr}
    end

    @spec part_role(Selfroles.User.t, Selfroles.Role.t) :: Selfroles.User.t
    def part_role(user, role) do
        nr = Selfroles.Role.drop(user.roles, role)
        %Selfroles.User{user | roles: nr}
    end

    defp roles_to_string_(r, o, len, n) when n < len do
        role = Enum.at(r, n)
        o = o <> "#{role.name}, "
        roles_to_string_(r, o, len, n+1)
    end

    defp roles_to_string_(r, o, len, n) when n >= len do
        String.slice(o, 0, String.length(o)-2)
    end

    def roles_to_string(r) do
        roles_to_string_(r, "", length(r), 0)
    end

    defp has_role_(user, role, o, len, n) when n < len do
        roles = user.roles
        r = Enum.at(roles, n)
        if Selfroles.Role.equals(role, r) do
            has_role_(user, role, true, len, len)
        else
            has_role_(user, role, o, len, len)
        end
    end

    defp has_role_(user, role, o, len, n) when n >= len do
        o
    end

    @spec has_role(Selfroles.User.t, Selfroles.Role.t) :: boolean
    def has_role(user, role) do
        has_role_(user, role, false, length(user.roles), 0)
    end

    defp drop_(arr, e, o, len, n) when n < len do
        el = Enum.at(arr, n)
        if el.id != e.id and el.roles != e.roles do
            o = o ++ [el]
        end
        drop_(arr, e, o, len, n+1)
    end

    defp drop_(arr,e,o,len,n) when n >= len do
        o
    end

    def drop(arr, e = %Selfroles.User{}) do
        drop_(arr, e, [], length(arr), 0)
    end

    def is(a = %Selfroles.User{}) do
        true
    end
    def is(a) do
        false
    end
end

defmodule Selfroles.Role do
@enforce_keys [:name]
defstruct name: "", users: []
@type t :: %Selfroles.Role{}

    def add(role = %Selfroles.Role{}, user = %Selfroles.User{}) do
        u = role.users ++ [user]
        %Selfroles.Role{role | users: u}
    end

    def remove(role = %Selfroles.Role{}, user = %Selfroles.User{}) do
        u = Selfroles.User.drop(role.users, user)
        %Selfroles.Role{role | users: u}
    end

    defp drop_(arr, e, o, len, n) when n < len do
        el = Enum.at(arr, n)
        if el.name != e.name and el.users != e.users do
            o = o ++ [el]
        end
        drop_(arr, e, o, len, n+1)
    end

    defp drop_(arr,e,o,len,n) when n >= len do
        o
    end

    def drop(arr, e = %Selfroles.Role{}) do
        drop_(arr, e, [], length(arr), 0)
    end

    def equals(a = %Selfroles.Role{}, b = %Selfroles.Role{}) do
        if a.name == b.name do
            true
        else
            false
        end
    end

    def is(a = %Selfroles.Role{}) do
        true
    end
    def is(a) do
        false
    end
end

defmodule Selfroles.Spinlock do
    def start() do
        p = spawn_link fn ->
            roll(%{
                roles: [],
                users: []
            })
        end
        Process.register(p, :selfroles)
        {:ok}
    end

    defp find_role_(roles, name, o, len, n) when n < len do
        role = Enum.at(roles, n)
        if role != nil do
            if role.name == name do
                o = role
                find_role_(roles, name, o, len, len)
            end
        end
        find_role_(roles, name, o, len, n+1)
    end

    defp find_role_(roles, name, o, len, n) when n >= len do
        o
    end

    defp find_user_(users, id, o, len, n) when n < len do
        user = Enum.at(users, n)
        if user != nil do
            if user.id == id do
                o = user
                find_user_(users, id, o, len, len)
            end
        end
        find_user_(users, id, o, len, n+1)
    end

    defp find_user_(users, id, o, len, n) when n >= len do
        o
    end

    defp find_role(roles, name) do
        find_role_(roles, name, nil, length(roles), 0)
    end

    defp find_user(users, id) do
        find_user_(users, id, nil, length(users), 0)
    end

    defp roll(map) do
        receive do
            {:add_role, role, pid} ->
                if Selfroles.Role.is role do
                    r = find_role(map[:roles], role.name)
                    if r == nil do
                        nr = map[:roles] ++ [role]
                        map = %{map | roles: nr}
                        send pid, {:ok}
                    else
                        send pid, {:error, :duplicate}
                    end
                end
            {:rem_role, role, pid} ->
                if Selfroles.Role.is role do
                    r = find_role(map[:roles], role.name)
                    if r != nil do
                        nr = Enum.drop(map[:roles], r)
                        map = %{map | roles: nr}
                        send pid, {:ok}
                    else
                        send pid, {:error, :notfound}
                    end                    
                end
            {:register_user, user, pid} ->
                if Selfroles.User.is user do
                    u = find_user(map[:users], user.id)
                    if u == nil do
                        nu = map[:users] ++ [user]
                        map = %{map | users: nu}
                        send pid, {:ok}
                    else
                        send pid, {:error, :duplicate}
                    end
                end
            {:get_role, name, pid} ->
                r = find_role(map[:roles], name)
                if r != nil do
                    send pid, {:ok, r}
                else
                    send pid, {:error, :notfound}
                end
            {:get_user, id, pid} ->
                user = find_user(map[:users], id)
                if user != nil do
                    send pid, {:ok, user}
                else
                    send pid, {:error, :notfound}
                end
            {:join, user, role, pid} ->
                if Selfroles.Role.is(role) and Selfroles.User.is(user) do
                    if !Selfroles.User.has_role(user, role) do
                        u = Selfroles.User.join_role(user, role)
                        r = Selfroles.Role.add(role, u)
                        roles = Selfroles.Role.drop(map[:roles], role) ++ [r]
                        users = Selfroles.User.drop(map[:users], user) ++ [u]
                        map = %{map | roles: roles, users: users}
                        send pid, {:ok}
                    else
                        send pid, {:error, :hasrole}
                    end
                end
            {:part, user, role, pid} ->
                if Selfroles.Role.is(role) and Selfroles.User.is(user) do
                    if Selfroles.User.has_role(user, role) do
                        r2 = find_role(map[:roles], role.name)
                        r = Selfroles.Role.remove(r2, user)
                        u = Selfroles.User.part_role(user, role)
                        roles = Selfroles.Role.drop(map[:roles], role) ++ [r]
                        users = Selfroles.User.drop(map[:users], user) ++ [u]
                        map = %{map | roles: roles, users: users}
                        send pid, {:ok}
                    else
                        send pid, {:error, :hasnorole}
                    end
                end
            {:inspect, pid} ->
                if Process.whereis(:console) == pid do
                    IO.puts("\rusers:#{inspect map[:users]}\nroles:#{inspect map[:roles]}")
                end
        end
        roll(map)
    end
end