
use Bitwise
require Logger
require Poison
require DiscordEx
alias DiscordEx.RestClient.Resources.Channel

defmodule RichEmbedField do
@enforce_keys [:name, :value]
defstruct name: "", value: "", inline: false
    def is(a = %RichEmbedField{}) do
        true
    end
    def is(a) do
        false
    end

    def to_field(rtf = %RichEmbedField{}) do
        %{inline: rtf.inline, name: rtf.name, value: rtf.value}
    end
end

defmodule RichEmbedAuthor do
@enforce_keys [:name]
defstruct name: "", icon_url: "", proxy_icon_url: ""
    def is(a = %RichEmbedAuthor{}) do
        true
    end
    def is(a) do
        false
    end

    def to_field(rtf = %RichEmbedAuthor{}) do
        %{name: rtf.name, icon_url: rtf.icon_url, proxy_icon_url: rtf.proxy_icon_url}
    end
end

defmodule RichEmbedFooter do
@enforce_keys [:text]
defstruct text: "", icon_url: "", proxy_icon_url: ""
    def is(a = %RichEmbedFooter{}) do
        true
    end
    def is(a) do
        false
    end

    def to_field(rtf = %RichEmbedFooter{}) do
        %{text: rtf.text, icon_url: rtf.icon_url, proxy_icon_url: rtf.proxy_icon_url}
    end
end

defmodule RichEmbedThumbnail do
@enforce_keys [:url]
defstruct width: 0, height: 0, url: "", proxy_url: ""
    def is(a = %RichEmbedThumbnail{}) do
        true
    end
    def is(a) do
        false
    end

    def to_field(rtf = %RichEmbedThumbnail{}) do
        %{width: rtf.width, height: rtf.height, url: rtf.url, proxy_url: rtf.proxy_url}
    end
end

defmodule RichColor do

    defp get_byte(from, byte) do
        (from >>> (8 * byte)) &&& 0xff
    end

    defp r(from) do
        get_byte(from, 2)
    end

    defp g(from) do
        get_byte(from, 1)
    end

    defp b(from) do
        get_byte(from, 0)
    end

    def to_tuple(color) do
        {r(color), g(color), b(color)}
    end

    def from_tuple(rgb) do
        r = elem(rgb, 0)
        g = elem(rgb, 1)
        b = elem(rgb, 2)

        color = ((r &&& 0xff) <<< 16)
        color = bxor(color, ((g &&& 0xff) <<< 8))
        color = bxor(color, (b &&& 0xff))
        color
    end

end

defmodule RichEmbed do
@enforce_keys [:color, :fields]
defstruct color: 0, desc: "", fields: [], footer: %{}, thumbnail: %{}, author: %{}

    defp rtfs_to_fs(arr, o, len, n) when n < len do
        e = Enum.at(arr, n)
        if RichEmbedField.is(e) do
            e_ = RichEmbedField.to_field(e)
            o = o ++ [e_]
        end
        rtfs_to_fs(arr, o, len, n+1)
    end
    defp rtfs_to_fs(arr, o, len, n) when n >= len do
        o
    end
    defp rtfs_to_fs(arr) do
        rtfs_to_fs(arr, [], length(arr), 0)
    end

    def send(rich_struct = %RichEmbed{}, c_map, channel) do
        {:ok, e} = gen(rich_struct)
        Channel.send_message(c_map.state[:rest_client], channel, e)
    end

    def gen(rich_struct = %RichEmbed{}) do
        color = RichColor.from_tuple(rich_struct.color)
        desc = rich_struct.desc
        fields = rtfs_to_fs(rich_struct.fields)
        footer = rich_struct.footer
        thumbnail = rich_struct.thumbnail
        author = rich_struct.author

        if footer != %{} do
            footer = RichEmbedFooter.to_field(footer)
        end

        if author != %{} do
            author = RichEmbedAuthor.to_field(author)
        end

        if thumbnail != %{} do
            thumbnail = RichEmbedThumbnail.to_field(thumbnail)
        end

        embed = 
        %{
            type: "rich", 
            title: "",
            color: color, 
            description: desc, 
            fields: fields, 
            footer: footer, 
            thumbnail: thumbnail,
            author: author
        }

        {:ok, %{content: "", embed: embed}}
    end
end