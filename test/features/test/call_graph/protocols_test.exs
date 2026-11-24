defmodule HologramFeatureTests.ProtocolsTest do
  use HologramFeatureTests.TestCase, async: true

  alias HologramFeatureTests.CallGraph.ProtocolsPage

  describe "custom protocol" do
    test "dispatch for atom", %{page: page} do
      page
      |> visit(ProtocolsPage)
      |> click_button("Dispatch custom for atom")
      |> assert_text("#result", inspect("atom(hello)"))
    end

    test "dispatch for struct", %{page: page} do
      page
      |> visit(ProtocolsPage)
      |> click_button("Dispatch custom for struct")
      |> assert_text("#result", inspect("<<7|test>>"))
    end
  end

  describe "Enumerable" do
    test "dispatch for list", %{page: page} do
      page
      |> visit(ProtocolsPage)
      |> click_button("Dispatch Enumerable for list")
      |> assert_text("#result", inspect([30, 60, 90]))
    end

    test "dispatch for custom struct", %{page: page} do
      page
      |> visit(ProtocolsPage)
      |> click_button("Dispatch Enumerable for struct")
      |> assert_text("#result", inspect([20, 40, 60]))
    end
  end
end
