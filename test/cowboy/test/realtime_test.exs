defmodule HologramCowboyTests.RealtimeTest do
  use HologramCowboyTests.TestCase, async: false

  alias HologramCowboyTests.RealtimePage

  @channel {:room, 1}

  test "a broadcast from a handler reaches every subscribed tab",
       %{browser: browser, page: session_1} do
    session_1 = visit(session_1, RealtimePage)
    session_2 = visit(new_session(browser), RealtimePage)

    # Both connections must be subscribed before the broadcast.
    wait_for_subscription(session_2, @channel, 2)

    click(session_1, "#broadcast")

    assert_text(session_1, "#received", "delivered from a handler")
    assert_text(session_2, "#received", "delivered from a handler")
  end
end
