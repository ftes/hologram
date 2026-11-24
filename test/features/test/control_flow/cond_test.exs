defmodule HologramFeatureTests.ControlFlow.CondTest do
  use HologramFeatureTests.TestCase, async: true
  alias HologramFeatureTests.ControlFlow.CondPage

  # single-expression clause condition / single clause / single-expression clause body
  test "basic case", %{page: page} do
    page
    |> visit(CondPage)
    |> click_button("Basic case")
    |> assert_text("#result", ":a")
  end

  test "multiple-expression clause condition", %{page: page} do
    page
    |> visit(CondPage)
    |> click_button("Multiple-expression clause condition")
    |> assert_text("#result", ":a")
  end

  test "multiple clauses", %{page: page} do
    page
    |> visit(CondPage)
    |> click_button("Multiple clauses")
    |> assert_text("#result", ":b")
  end

  test "multiple-expression clause body", %{page: page} do
    page
    |> visit(CondPage)
    |> click_button("Multiple-expression clause body")
    |> assert_text("#result", ":b")
  end

  test "evaluates the first clause with truthy condition", %{page: page} do
    page
    |> visit(CondPage)
    |> click_button("Evaluates the first clause with truthy condition")
    |> assert_text("#result", ":c")
  end

  test "vars scoping", %{page: page} do
    page
    |> visit(CondPage)
    |> click_button("Vars scoping")
    |> assert_text("#result", "{1, 2, 3, {14, 5, 3}}")
  end

  test "no matching clause", %{page: page} do
    assert_client_error page,
                        CondClauseError,
                        "no cond clause evaluated to a truthy value",
                        fn ->
                          page
                          |> visit(CondPage)
                          |> click_button("No matching clause")
                        end
  end

  test "error in clause condition", %{page: page} do
    assert_client_error page,
                        RuntimeError,
                        "my message",
                        fn ->
                          page
                          |> visit(CondPage)
                          |> click_button("Error in clause condition")
                        end
  end

  test "error in clause body", %{page: page} do
    assert_client_error page,
                        ArgumentError,
                        "my message",
                        fn ->
                          page
                          |> visit(CondPage)
                          |> click_button("Error in clause body")
                        end
  end
end
