defmodule HologramFeatureTests.SharedFunctionsTest do
  use HologramFeatureTests.TestCase, async: true

  alias HologramFeatureTests.CallGraph.SharedFunctionsPage1
  alias HologramFeatureTests.CallGraph.SharedFunctionsPage2
  alias HologramFeatureTests.CallGraph.SharedFunctionsPage3

  test "a page reaching only fun_a", %{page: page} do
    page
    |> visit(SharedFunctionsPage1)
    |> click_button("Call fun_a")
    |> assert_text("#result", inspect("fun_a"))
  end

  test "a page reaching only fun_b", %{page: page} do
    page
    |> visit(SharedFunctionsPage2)
    |> click_button("Call fun_b")
    |> assert_text("#result", inspect("fun_b"))
  end

  test "a page reaching both functions gets both", %{page: page} do
    page
    |> visit(SharedFunctionsPage3)
    |> click_button("Call fun_a")
    |> assert_text("#result", inspect("fun_a"))
    |> click_button("Call fun_b")
    |> assert_text("#result", inspect("fun_b"))
  end
end
