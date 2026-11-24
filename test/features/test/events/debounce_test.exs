defmodule HologramFeatureTests.Events.DebounceTest do
  use HologramFeatureTests.TestCase, async: true

  alias HologramFeatureTests.Events.Debounce.Page1
  alias HologramFeatureTests.Events.Debounce.Page2
  alias HologramFeatureTests.Events.Debounce.Page3
  alias HologramFeatureTests.Events.Debounce.Page4

  test "debounce coalesces a burst of events that an undebounced binding fires individually",
       %{page: page} do
    page
    |> visit(Page1)
    |> type_in("#my_input", with: "abcde")
    |> assert_text("#plain_result", ~s/{5, "e"}/)
    |> assert_text("#debounced_result", ~s/{1, "e"}/)
  end

  # The debounce window is far longer than the assertion timeout, so the result can only appear
  # through the blur flush, never through the window elapsing.
  test "blurring the input flushes its pending debounced dispatch", %{page: page} do
    page
    |> visit(Page1)
    |> fill_in("#blur_input", with: "holo")
    |> click("#my_input")
    |> assert_text("#blurred_result", ~s/"holo"/)
  end

  # Submitting via Enter keeps focus in the input, so no blur flush kicks in beforehand - the
  # submit action can only observe the typed value if the submit flush ran the pending change
  # dispatch first.
  test "submitting the form flushes its pending debounced dispatches first",
       %{page: page} do
    page
    |> visit(Page1)
    |> fill_in("#submit_input", with: "flush")
    |> send_keys("Enter")
    |> assert_text("#submitted_result", ~s/"flush"/)
  end

  # Positive control for the cancellation scenario below: the same hover schedules a dispatch
  # that fires when the user stays on the page.
  test "a pending debounced dispatch fires when the user stays on the page",
       %{page: page} do
    page
    |> visit(Page2)
    |> hover("#hover_zone")
    |> assert_text("#layout_result", ~s/"mouse_moved"/)
  end

  # The pending dispatch is keyed on the hover zone, which never has focus, so no blur flush runs
  # when the link is clicked - the dispatch is still pending when navigation happens. Waiting out
  # the rest of the window on the destination page proves the dispatch was cancelled rather than
  # delayed: the layout is re-rendered there, so a post-navigation fire would show up in its result.
  test "navigating to another page cancels a pending debounced dispatch",
       %{page: page} do
    page
    |> install_clock()
    |> visit(Page2)
    |> hover("#hover_zone")
    |> click_link("Page 3 link")
    |> assert_page(Page3)
    |> run_for(3_000)
    |> assert_text("#layout_result", "nil")
  end

  # The same scenario as above with the destination's mount held off, which puts the pending
  # dispatch's deadline inside the stretch where the destination is displayed but the registry
  # still answers for the page that armed it. Two independent things keep the dispatch off the
  # destination there - it is cancelled when the page is left, and were it not, it carries the
  # epoch of the page it was armed on and would be dropped on settling - so this passes with
  # either one alone. It is here to hold the pair, not to single out the cancellation.
  test "a pending debounced dispatch does not survive into a destination still fetching its bundle",
       %{page: page} do
    page
    |> install_clock()
    |> simulate_slow_page_bundle(4_000)
    |> visit(Page2)
    |> hover("#hover_zone")
    |> click_link("Page 3 link")
    |> assert_page(Page3)
    |> run_for(3_000)
    |> assert_text("#layout_result", "nil")
  end

  # Escape removes the editor while the input still has focus, so the browser fires focusout from
  # inside the removal and the pending debounced dispatch is flushed while the page is halfway
  # patched. The recorded value says that dispatch was delivered, and the editor being gone says
  # the render that removed it ran to the end.
  test "closing a focused editor delivers its pending debounced dispatch",
       %{page: page} do
    page
    |> visit(Page4)
    |> fill_in("#editor_input", with: "abc")
    |> send_keys("Escape")
    |> assert_text("#typed_result", ~s/"abc"/)
    |> refute_has("#editor_block")
  end
end
