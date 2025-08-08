defmodule Glory.Input do
  require Logger
  import WxRecords

  def init() do
    :persistent_term.put({__MODULE__, :mouse_x}, 0)
    :persistent_term.put({__MODULE__, :mouse_y}, 0)
  end

  # we can just match on type, but matching on the specific mouse event type
  # (:motion, :left_down, :middle_dclick, etc.) lets us be more specific.
  def handler(wx(event: wxMouse(type: :motion, x: x, y: y)), state) do
    :persistent_term.put({__MODULE__, :mouse_x}, x)
    :persistent_term.put({__MODULE__, :mouse_y}, y)
    {:noreply, state}
  end

  def handler(wx(event: wxKey(type: type, x: _x, y: _y, keyCode: key_code)), state) do
    :wx_object.cast(Glory.Window, {type, key_code})

    {:noreply, state}
  end

  def handler(request, state) do
    Logger.debug(request: request, state: state)

    {:noreply, state}
  end
end
