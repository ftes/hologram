defmodule HologramFeatureTests.Events.DocumentTest do
  use HologramFeatureTests.TestCase, async: true

  alias HologramFeatureTests.Events.DocumentPage

  test "handles a global event", %{page: page} do
    page
    |> visit(DocumentPage)
    |> send_keys("Control+k")
    |> assert_text("#shortcut_result", "1")
  end

  test "activates a conditionally rendered binding", %{page: page} do
    page
    |> visit(DocumentPage)
    # Before its branch renders, Escape must not dispatch. The handled shortcut is a happens-after
    # barrier: once it lands, the earlier Escape has been processed too, so a zero count is reliable.
    |> send_keys("Escape")
    |> send_keys("Control+k")
    |> assert_text("#shortcut_result", "1")
    |> assert_text("#escape_result", "0")
    # Rendering the gated <document> activates the escape binding.
    |> click("#toggle_listening")
    |> send_keys("Escape")
    |> assert_text("#escape_result", "1")
  end

  test "deactivates a binding that is no longer rendered", %{page: page} do
    page
    |> visit(DocumentPage)
    # Render the gated <document>, then confirm Escape dispatches.
    |> click("#toggle_listening")
    |> send_keys("Escape")
    |> assert_text("#escape_result", "1")
    # Removing the gated <document> deactivates it. The shortcut barrier confirms the later Escape was
    # processed, so the unchanged escape count proves it did not dispatch.
    |> click("#toggle_listening")
    |> send_keys("Escape")
    |> send_keys("Control+k")
    |> assert_text("#shortcut_result", "1")
    |> assert_text("#escape_result", "1")
  end

  # A <document> tag renders to nil on the client; that nil must be dropped, not
  # turned into a stray "undefined" text node next to the page content.
  test "does not render a stray \"undefined\" text node", %{page: page} do
    page
    |> visit(DocumentPage)
    |> refute_has("body", text: "undefined")
  end
end
