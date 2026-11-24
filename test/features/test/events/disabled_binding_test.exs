defmodule HologramFeatureTests.Events.DisabledBindingTest do
  use HologramFeatureTests.TestCase, async: true

  alias HologramFeatureTests.Events.DisabledBindingPage

  # Clicks are dispatched in order, so asserting on a later verified action's update proves the
  # earlier disabled clicks have settled, while the rendered state tuple proves they changed
  # nothing.

  test "disabled bindings dispatch nothing while the page stays functional",
       %{page: page} do
    page
    |> visit(DisabledBindingPage)
    |> click("#disabled_longhand_action")
    |> click("#disabled_longhand_action_with_params")
    |> click("#disabled_longhand_command")
    |> click("#disabled_shorthand")
    |> click("#ping")
    |> assert_text("#result", "{nil, nil, false, true}")
  end

  test "conditional binding dispatches only once enabled", %{page: page} do
    page
    |> visit(DisabledBindingPage)
    |> click("#conditional")
    |> click("#enable")
    |> assert_text("#result", "{nil, nil, true, false}")
    |> click("#conditional")
    |> assert_text("#result", "{:executed, nil, true, false}")
  end

  test "conditional binding with params dispatches only once enabled",
       %{page: page} do
    page
    |> visit(DisabledBindingPage)
    |> click("#conditional_with_params")
    |> click("#enable")
    |> assert_text("#result", "{nil, nil, true, false}")
    |> click("#conditional_with_params")
    |> assert_text("#result", "{nil, 1, true, false}")
  end

  test "disabled binding leaves the native default behavior untouched",
       %{page: page} do
    page
    |> visit(DisabledBindingPage)
    |> click("#checkbox")
    |> assert_has("#checkbox:checked")
    |> click("#enable")
    |> assert_text("#result", "{nil, nil, true, false}")
  end
end
