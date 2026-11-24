defmodule HologramFeatureTests.ControlFlow.CaseTest do
  use HologramFeatureTests.TestCase, async: true

  alias HologramFeatureTests.ControlFlow.CasePage

  # single-expression condition / single clause / single-expression clause body
  test "basic case", %{page: page} do
    page
    |> visit(CasePage)
    |> click_button("Basic case")
    |> assert_text("#result", ":a")
  end

  test "multiple-expression condition", %{page: page} do
    page
    |> visit(CasePage)
    |> click_button("Multiple-expression condition")
    |> assert_text("#result", ":a")
  end

  test "multiple clauses", %{page: page} do
    page
    |> visit(CasePage)
    |> click_button("Multiple clauses")
    |> assert_text("#result", ":b")
  end

  test "multiple-expression clause body", %{page: page} do
    page
    |> visit(CasePage)
    |> click_button("Multiple-expression clause body")
    |> assert_text("#result", ":b")
  end

  test "vars matching", %{page: page} do
    page
    |> visit(CasePage)
    |> click_button("Vars matching")
    |> assert_text("#result", "{1, 2, 3}")
  end

  test "vars scoping", %{page: page} do
    page
    |> visit(CasePage)
    |> click_button("Vars scoping")
    |> assert_text("#result", "{1, 2, {1, 3}}")
  end

  test "var match in condition", %{page: page} do
    page
    |> visit(CasePage)
    |> click_button("Var match in condition")
    |> assert_text("#result", "{1, 2, {3, 2}}")
  end

  test "no matching clause", %{page: page} do
    assert_client_error page,
                        CaseClauseError,
                        "no case clause matching:\n\n    3\n",
                        fn ->
                          page
                          |> visit(CasePage)
                          |> click_button("No matching clause")
                        end
  end

  test "error in condition", %{page: page} do
    assert_client_error page,
                        RuntimeError,
                        "my message",
                        fn ->
                          page
                          |> visit(CasePage)
                          |> click_button("Error in condition")
                        end
  end

  test "error_in_clause_body", %{page: page} do
    assert_client_error page,
                        ArgumentError,
                        "my message",
                        fn ->
                          page
                          |> visit(CasePage)
                          |> click_button("Error in clause body")
                        end
  end

  test "struct pattern with var field", %{page: page} do
    page
    |> visit(CasePage)
    |> click_button("Struct pattern with var field")
    |> assert_text("#result", "42")
  end

  test "partial struct pattern", %{page: page} do
    page
    |> visit(CasePage)
    |> click_button("Partial struct pattern")
    |> assert_text("#result", ":matched")
  end

  test "bare struct pattern", %{page: page} do
    page
    |> visit(CasePage)
    |> click_button("Bare struct pattern")
    |> assert_text("#result", ":matched")
  end

  test "struct pattern with guard", %{page: page} do
    page
    |> visit(CasePage)
    |> click_button("Struct pattern with guard")
    |> assert_text("#result", "42")
  end

  test "map vs struct pattern", %{page: page} do
    page
    |> visit(CasePage)
    |> click_button("Map vs struct pattern")
    |> assert_text("#result", ":fallback")
  end

  # TODO: expect the BEAM form, %HologramFeatureTests.StructFixture1{name: "other", value: 7},
  # once client-side struct inspect is implemented (see the "TODO: inspect structs" note on
  # Interpreter.#inspectMap/2 in assets/js/interpreter.mjs). The client renders structs as
  # plain maps for now - the same form asserted in call_graph/dynamic_dispatch_test.exs.
  test "unmatched struct pattern", %{page: page} do
    assert_client_error page,
                        CaseClauseError,
                        ~s(no case clause matching:\n\n    %{__struct__: HologramFeatureTests.StructFixture1, name: "other", value: 7}\n),
                        fn ->
                          page
                          |> visit(CasePage)
                          |> click_button("Unmatched struct pattern")
                        end
  end
end
