defmodule HologramFeatureTests.ControlFlow.WithTest do
  use HologramFeatureTests.TestCase, async: true

  alias HologramFeatureTests.ControlFlow.WithPage

  # IMPORTANT!
  # Each feature test has a related JavaScript test in test/javascript/interpreter_test.mjs (with() section)
  # and a related Elixir consistency test in test/elixir/hologram/ex_js_consistency/with_test.exs.
  # Always update all three together.

  test "evaluates the body when there are no clauses", %{page: page} do
    page
    |> visit(WithPage)
    |> click_button("Auxiliary")
    |> assert_text("#result", ":auxiliary")
    |> click_button("Empty with")
    |> assert_text("#result", "nil")
  end

  test "returns the unmatched value when there are no else clauses", %{
    page: page
  } do
    page
    |> visit(WithPage)
    |> click_button("No else clauses passthrough")
    |> assert_text("#result", ":ok")
  end

  describe "match clauses" do
    test "returns the body result for a single matching clause", %{
      page: page
    } do
      page
      |> visit(WithPage)
      |> click_button("Single matching clause")
      |> assert_text("#result", "{:ok, :ok}")
    end

    test "returns the body result for multiple matching clauses", %{
      page: page
    } do
      page
      |> visit(WithPage)
      |> click_button("Multiple matching clauses")
      |> assert_text("#result", "{:ok, :ok}")
    end

    test "returns the body result for a clause with a passing guard", %{
      page: page
    } do
      page
      |> visit(WithPage)
      |> click_button("Clause with passing guard")
      |> assert_text("#result", "{:ok, :ok}")
    end
  end

  describe "bare clauses" do
    test "evaluates a bare expression clause that binds a variable", %{
      page: page
    } do
      page
      |> visit(WithPage)
      |> click_button("Bare clause that binds")
      |> assert_text("#result", "{:ok, :ok}")
    end

    test "evaluates a bare expression clause that does not bind a variable", %{
      page: page
    } do
      page
      |> visit(WithPage)
      |> click_button("Bare clause that does not bind")
      |> assert_text("#result", "{:ok, :ok}")
    end

    test "evaluates multiple bare expression clauses", %{page: page} do
      page
      |> visit(WithPage)
      |> click_button("Multiple bare clauses")
      |> assert_text("#result", "{:ok, :ok, :ok}")
    end

    test "raises a MatchError when a bare clause fails to match", %{
      page: page
    } do
      assert_client_error page,
                          MatchError,
                          "no match of right hand side value:\n\n    :ok\n",
                          fn ->
                            page
                            |> visit(WithPage)
                            |> click_button("Bare clause MatchError")
                          end
    end
  end

  describe "else clauses" do
    test "routes a failed match to a single else clause", %{page: page} do
      page
      |> visit(WithPage)
      |> click_button("Failed match to single else")
      |> assert_text("#result", ":match")
    end

    test "selects the matching clause among multiple else clauses", %{
      page: page
    } do
      page
      |> visit(WithPage)
      |> click_button("Matching clause among multiple else")
      |> assert_text("#result", ":second")
    end

    test "selects a guarded else clause when its guard passes", %{
      page: page
    } do
      page
      |> visit(WithPage)
      |> click_button("Guarded else clause")
      |> assert_text("#result", "{:guarded, :ok}")
    end

    test "routes a failed guard to the else clauses", %{page: page} do
      page
      |> visit(WithPage)
      |> click_button("Failed guard to else")
      |> assert_text("#result", "{:error, :nomatch}")
    end

    test "raises WithClauseError when no else clause matches", %{
      page: page
    } do
      assert_client_error page,
                          WithClauseError,
                          "no with clause matching:\n\n    :ok\n",
                          fn ->
                            page
                            |> visit(WithPage)
                            |> click_button("No matching else clause")
                          end
    end
  end

  describe "variable scoping" do
    test "does not leak assignments into the original context", %{
      page: page
    } do
      page
      |> visit(WithPage)
      |> click_button("Does not leak")
      |> assert_text("#result", ":ok")
    end

    test "evaluates else clauses in the original context", %{page: page} do
      page
      |> visit(WithPage)
      |> click_button("Else in original context")
      |> assert_text("#result", ":original")
    end

    test "lets a later clause shadow an earlier binding", %{page: page} do
      page
      |> visit(WithPage)
      |> click_button("Later clause shadows")
      |> assert_text("#result", "3")
    end
  end
end
