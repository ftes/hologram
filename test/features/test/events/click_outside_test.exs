defmodule HologramFeatureTests.Events.ClickOutsideTest do
  use HologramFeatureTests.TestCase, async: true

  alias HologramFeatureTests.Events.ClickOutsidePage

  test "opening the element does not immediately close it", %{page: page} do
    page
    |> visit(ClickOutsidePage)
    |> click("#open")
    |> assert_has("#panel")
    # The opening click must not register as an outside click - the document listener is installed
    # only on the open re-render, a turn after the click. The inside click is a happens-after
    # barrier: the opening click is queued before it, so once the note lands the opening click has
    # been processed and a zero close count is reliable.
    |> click("#inside")
    |> assert_text("#note_result", "1")
    |> assert_text("#close_result", "0")
    |> assert_has("#panel")
  end

  test "a click inside the element keeps it open", %{page: page} do
    page
    |> visit(ClickOutsidePage)
    |> click("#open")
    |> assert_has("#panel")
    # Two inside clicks. An inside click's own close would be queued during that same click, so the
    # second click's note is the happens-after barrier: once the note count reaches 2, the first
    # inside click has been fully processed and a zero close count proves it did not close.
    |> click("#inside")
    |> click("#inside")
    |> assert_text("#note_result", "2")
    |> assert_text("#close_result", "0")
    |> assert_has("#panel")
  end

  test "a click outside the element closes it", %{page: page} do
    page
    |> visit(ClickOutsidePage)
    |> click("#open")
    |> assert_has("#panel")
    |> click("#outside")
    |> assert_text("#close_result", "1")
    |> refute_has("#panel")
  end
end
