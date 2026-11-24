defmodule HologramFeatureTests.Events.MultipleBindingsTest do
  use HologramFeatureTests.TestCase, async: true

  alias HologramFeatureTests.Events.MultipleBindingsPage

  test "bindings for the same event run in the order they are written",
       %{page: page} do
    page
    |> visit(MultipleBindingsPage)
    |> click("#order_button")
    |> assert_text("#order_result", "[:first, :second]")
  end

  # The result is an append log asserted as an exact sequence, so a filter spuriously firing on
  # another filter's key shows up as an extra entry instead of hiding behind the last write.
  test "several key filters on one element each fire only on their own key",
       %{page: page} do
    page
    |> visit(MultipleBindingsPage)
    |> send_keys("#filter_input", "Enter")
    |> assert_text("#filter_result", "[:enter_matched]")
    |> send_keys("#filter_input", "Escape")
    |> assert_text("#filter_result", "[:enter_matched, :escape_matched]")
  end

  test "two debounced bindings with different windows on the same event each fire independently",
       %{page: page} do
    page
    |> visit(MultipleBindingsPage)
    |> fill_in("#layered_input", with: "layered")
    # Observed between the two windows: the quick binding has already fired while the full one is
    # still pending, proving the windows are distinct rather than both dispatching together.
    |> assert_text("#quick_result", ~s/"layered"/)
    |> assert_text("#full_result", "nil")
    |> assert_text("#full_result", ~s/"layered"/)
  end
end
