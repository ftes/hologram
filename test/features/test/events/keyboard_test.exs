defmodule HologramFeatureTests.Events.KeyboardTest do
  use HologramFeatureTests.TestCase, async: true

  alias HologramFeatureTests.Events.KeyboardPage

  test "key down", %{page: page} do
    page
    |> visit(KeyboardPage)
    |> type_in("#my_input_key_down", with: "a")
    |> assert_text(
      "#result",
      ~r/\{:key_down, %\{event: %\{alt_key: false, code: "KeyA", ctrl_key: false, key: "a", meta_key: false, repeat: false, shift_key: false\}\}\}/
    )
  end

  test "key up", %{page: page} do
    page
    |> visit(KeyboardPage)
    |> type_in("#my_input_key_up", with: "a")
    |> assert_text(
      "#result",
      ~r/\{:key_up, %\{event: %\{alt_key: false, code: "KeyA", ctrl_key: false, key: "a", meta_key: false, repeat: false, shift_key: false\}\}\}/
    )
  end

  test "typing is not blocked", %{page: page} do
    page
    |> visit(KeyboardPage)
    |> fill_in("#my_input_key_down", with: "abc")
    |> assert_input_value("#my_input_key_down", "abc")
  end

  test "single key filter", %{page: page} do
    page
    |> visit(KeyboardPage)
    |> send_keys("#my_input_enter", "Escape")
    |> assert_text("#result", "nil")
    |> send_keys("#my_input_enter", "Enter")
    |> assert_text(
      "#result",
      ~r/\{:enter, %\{event: %\{alt_key: false, code: "Enter", ctrl_key: false, key: "Enter", meta_key: false, repeat: false, shift_key: false\}\}\}/
    )
  end

  test "keys combo", %{page: page} do
    page
    |> visit(KeyboardPage)
    |> send_keys("#my_input_ctrl_k", "k")
    |> assert_text("#result", "nil")
    |> send_keys("#my_input_ctrl_k", "Control+k")
    |> assert_text(
      "#result",
      ~r/\{:ctrl_k, %\{event: %\{alt_key: false, code: "KeyK", ctrl_key: true, key: "k", meta_key: false, repeat: false, shift_key: false\}\}\}/
    )
  end

  test "key filters on key_down", %{page: page} do
    page
    |> visit(KeyboardPage)
    |> send_keys("#my_input_key_down_arrow_up", "ArrowUp")
    |> assert_text(
      "#result",
      ~r/\{:key_down_arrow_up, %\{event: %\{alt_key: false, code: "ArrowUp", ctrl_key: false, key: "ArrowUp", meta_key: false, repeat: false, shift_key: false\}\}\}/
    )
  end

  test "key filters on key_up", %{page: page} do
    page
    |> visit(KeyboardPage)
    |> send_keys("#my_input_key_up_arrow_up", "ArrowUp")
    |> assert_text(
      "#result",
      ~r/\{:key_up_arrow_up, %\{event: %\{alt_key: false, code: "ArrowUp", ctrl_key: false, key: "ArrowUp", meta_key: false, repeat: false, shift_key: false\}\}\}/
    )
  end

  test "special character filter", %{page: page} do
    page
    |> visit(KeyboardPage)
    |> send_keys("#my_input_slash", "/")
    |> assert_text(
      "#result",
      ~r{\{:slash, %\{event: %\{alt_key: false, code: "Slash", ctrl_key: false, key: "/", meta_key: false, repeat: false, shift_key: false\}\}\}}
    )
  end

  # A bare Event dispatched as keydown has no key, code or modifier flags, the shape Chromium
  # fires before it autofills a field. The result stays nil either way, so the check is that no
  # listener throws: an uncaught listener error fails the test (see track_js_errors/1).
  test "a keydown without a key is ignored", %{page: page} do
    page
    |> visit(KeyboardPage)
    |> execute_script("""
    for (const id of ["my_input_key_down", "my_input_enter"]) {
      document.getElementById(id).dispatchEvent(new Event("keydown", {bubbles: true}));
    }
    """)
    |> assert_text("#result", "nil")
  end
end
