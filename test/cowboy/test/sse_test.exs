defmodule HologramCowboyTests.SSETest do
  use HologramCowboyTests.TestCase, async: false

  alias Hologram.Realtime
  alias HologramCowboyTests.RealtimePage

  @channel {:room, 1}

  test "the stream attaches and stays open", %{page: page} do
    page
    |> visit(RealtimePage)
    |> wait_for_subscription(@channel)

    # A stream that dies right after opening dies within milliseconds of its 200, in the
    # same request. 2 s is policy, far past that.
    Process.sleep(2_000)

    Realtime.broadcast_action(@channel, :show, message: "delivered after a pause")

    assert_text(page, "#received", "delivered after a pause")
  end
end
