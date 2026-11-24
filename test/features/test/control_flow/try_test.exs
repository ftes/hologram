defmodule HologramFeatureTests.ControlFlow.TryTest do
  @moduledoc """
  These scenarios are confirmed against real Elixir by the consistency tests in test/elixir/hologram/ex_js_consistency/try_test.exs (paired with the JavaScript try() / asyncTry() tests in test/javascript/interpreter_test.mjs).
  Keep them in sync.
  """
  use HologramFeatureTests.TestCase, async: true

  alias HologramFeatureTests.ControlFlow.TryPage

  describe "rescue clauses" do
    test "without a module", %{page: page} do
      page
      |> visit(TryPage)
      |> click_button("Rescue without a module")
      |> assert_text("#result", ":rescued_any")
    end

    test "with a single module", %{page: page} do
      page
      |> visit(TryPage)
      |> click_button("Rescue with a single module")
      |> assert_text("#result", ~s/{:rescued_single, "my message"}/)
    end

    test "with multiple modules", %{page: page} do
      page
      |> visit(TryPage)
      |> click_button("Rescue with multiple modules")
      |> assert_text("#result", ~s/{:rescued_multiple, "my message"}/)
    end

    test "unmatched module re-raises", %{page: page} do
      assert_client_error page,
                          RuntimeError,
                          "my message",
                          fn ->
                            page
                            |> visit(TryPage)
                            |> click_button("Rescue unmatched module")
                          end
    end

    test "bare reason is normalized into an exception struct", %{page: page} do
      page
      |> visit(TryPage)
      |> click_button("Rescue bare reason")
      |> assert_text("#result", ~s/{:rescued_normalized, "argument error"}/)
    end

    test "reraise re-raises the rescued exception", %{page: page} do
      assert_client_error page,
                          ArgumentError,
                          "my message",
                          fn ->
                            page
                            |> visit(TryPage)
                            |> click_button("Rescue reraise")
                          end
    end
  end

  describe "catch clauses" do
    test "throw kind", %{page: page} do
      page
      |> visit(TryPage)
      |> click_button("Catch throw")
      |> assert_text("#result", ~s/{:caught_throw, "my value"}/)
    end

    test "exit kind", %{page: page} do
      page
      |> visit(TryPage)
      |> click_button("Catch exit")
      |> assert_text("#result", ~s/{:caught_exit, "my reason"}/)
    end

    test "error kind", %{page: page} do
      page
      |> visit(TryPage)
      |> click_button("Catch error")
      |> assert_text("#result", ~s/{:caught_error, "my message"}/)
    end

    test "unmatched kind re-raises", %{page: page} do
      assert_client_error page,
                          RuntimeError,
                          "my message",
                          fn ->
                            page
                            |> visit(TryPage)
                            |> click_button("Catch unmatched kind")
                          end
    end

    test "matches a struct pattern value", %{page: page} do
      page
      |> visit(TryPage)
      |> click_button("Catch struct throw")
      |> assert_text("#result", "{:caught, 1}")
    end
  end

  describe "__STACKTRACE__" do
    # The line `raise "boom"` sits on in app/pages/control_flow/try_page.ex.
    @raise_line 306

    # The line `raise "bang"` sits on in app/pages/control_flow/try_page.ex -
    # the raise site reraise has to preserve, not the clause re-raising it.
    @reraise_line 228

    test "holds the frame the error was raised in", %{page: page} do
      expected =
        "{:stacktrace, [{#{inspect(TryPage)}, :action, 3, " <>
          ~s([file: ~c"app/pages/control_flow/try_page.ex", ) <>
          "line: #{@raise_line}, error_info: %{module: Exception}]}]}"

      page
      |> visit(TryPage)
      |> click_button("Stacktrace")
      |> assert_text("#result", expected)
    end

    test "reraise preserves the frame of the original raise site", %{page: page} do
      expected =
        "{:reraise_stacktrace, [{#{inspect(TryPage)}, :action, 3, " <>
          ~s([file: ~c"app/pages/control_flow/try_page.ex", ) <>
          "line: #{@reraise_line}, error_info: %{module: Exception}]}]}"

      page
      |> visit(TryPage)
      |> click_button("Reraise stacktrace")
      |> assert_text("#result", expected)
    end
  end

  describe "else clauses" do
    test "matches the do result", %{page: page} do
      page
      |> visit(TryPage)
      |> click_button("Else with a match")
      |> assert_text("#result", ":else_two")
    end

    test "raises TryClauseError when no clause matches", %{page: page} do
      assert_client_error page,
                          TryClauseError,
                          "no try clause matching:\n\n    :no_match\n",
                          fn ->
                            page
                            |> visit(TryPage)
                            |> click_button("Else without a match")
                          end
    end

    test "matches a struct pattern", %{page: page} do
      page
      |> visit(TryPage)
      |> click_button("Else with a struct pattern")
      |> assert_text("#result", "{:else_matched, 2}")
    end
  end

  describe "after block" do
    test "keeps the do result", %{page: page} do
      page
      |> visit(TryPage)
      |> click_button("After keeps result")
      |> assert_text("#result", ":body_result")
    end

    test "runs on the success path", %{page: page} do
      assert_client_error page,
                          RuntimeError,
                          "after ran",
                          fn ->
                            page
                            |> visit(TryPage)
                            |> click_button("After runs on success")
                          end
    end

    test "runs on the failure path", %{page: page} do
      assert_client_error page,
                          RuntimeError,
                          "after ran",
                          fn ->
                            page
                            |> visit(TryPage)
                            |> click_button("After runs on failure")
                          end
    end
  end

  describe "variable scoping" do
    test "do block bindings do not leak", %{page: page} do
      page
      |> visit(TryPage)
      |> click_button("Do block vars do not leak")
      |> assert_text("#result", "{1, 2}")
    end

    test "clause bindings do not leak", %{page: page} do
      page
      |> visit(TryPage)
      |> click_button("Clause vars do not leak")
      |> assert_text("#result", "{1, 2}")
    end
  end
end
