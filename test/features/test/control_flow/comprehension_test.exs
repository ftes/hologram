defmodule HologramFeatureTests.ControlFlow.ComprehensionTest do
  use HologramFeatureTests.TestCase, async: true

  alias HologramFeatureTests.ControlFlow.ComprehensionPage

  # IMPORTANT!
  # Each feature test has a related JavaScript test in test/javascript/interpreter_test.mjs
  # (comprehension() and comprehensionReduce() sections)
  # and a related Elixir consistency test in test/elixir/hologram/ex_js_consistency/comprehension_test.exs.
  # Always update all three together.
  #
  # The mirroring is not complete yet - this file covers only the dependent-generator,
  # position-sensitive-filter, bitstring generator, and reducer tests.

  # TODO: mirror the remaining behavioral tests from the comprehension() section
  # of test/javascript/interpreter_test.mjs:
  # - enumerable generator: generates combinations of enumerables items
  # - enumerable generator: ignores enumerable items that don't match the pattern
  # - bitstring generator: matches segments narrower than a byte
  # - bitstring generator: generates combinations of bitstring generators
  # - bitstring generator: can use variables bound by an earlier generator
  # - bitstring generator: returns an empty result for an empty bitstring
  # - bitstring generator: removes duplicate results when the unique flag is set
  # - bitstring generator: raises ErlangError if the source is not a bitstring
  # - guards: single guard
  # - guards: multiple guards
  # - guards: can access variables from comprehension outer scope
  # - guards: can access variables pattern matched in preceding guards
  # - guards: errors raised inside generators are not caught
  # - filters: remove combinations that don't fullfill specified conditions
  # - filters: can access variables from comprehension outer scope
  # - unique: non-unique items are removed if 'uniq' option is set to true
  # - mapper: can access variables from comprehension outer scope
  # - mapper: uses Enum.into/2 to insert the comprehension result into a collectable

  describe "enumerable generator" do
    test "can use variables bound by an earlier generator", %{page: page} do
      page
      |> visit(ComprehensionPage)
      |> click_button("Dependent generator")
      |> assert_text("#result", "[{1, 1}, {1, 11}, {2, 2}, {2, 12}]")
    end

    test "matches a struct pattern", %{page: page} do
      page
      |> visit(ComprehensionPage)
      |> click_button("Generator with struct pattern")
      |> assert_text("#result", "[10, 20]")
    end

    test "ignores items that don't match a struct pattern", %{page: page} do
      page
      |> visit(ComprehensionPage)
      |> click_button("Struct filtering in generator")
      |> assert_text("#result", "[1, 3]")
    end
  end

  describe "bitstring generator" do
    test "iterates in pattern-sized steps", %{page: page} do
      page
      |> visit(ComprehensionPage)
      |> click_button("Basic bitstring generator")
      |> assert_text("#result", "[5, 6, 7]")
    end

    test "binds multiple segments per step", %{page: page} do
      page
      |> visit(ComprehensionPage)
      |> click_button("Bitstring generator with multi-segment pattern")
      |> assert_text("#result", "[{1, 2}, {3, 4}]")
    end

    test "stops iterating at the first non-matching prefix", %{page: page} do
      page
      |> visit(ComprehensionPage)
      |> click_button("Bitstring generator with prefix mismatch")
      |> assert_text("#result", "[2]")
    end

    test "discards leftover bits that don't fill the pattern", %{page: page} do
      page
      |> visit(ComprehensionPage)
      |> click_button("Bitstring generator with leftover bits")
      |> assert_text("#result", "[1, 2]")
    end

    test "composes with filters", %{page: page} do
      page
      |> visit(ComprehensionPage)
      |> click_button("Bitstring generator with filter")
      |> assert_text("#result", "[1, 3]")
    end
  end

  describe "filters" do
    test "placed between generators prunes the branch before the next generator runs", %{
      page: page
    } do
      page
      |> visit(ComprehensionPage)
      |> click_button("Guarding filter")
      |> assert_text("#result", "[1, 2, 3]")
    end
  end

  describe "unique" do
    # The expected text is a literal rather than inspect/1, because the page renders with
    # Hologram.Commons.KernelUtils.inspect/1, which sorts map keys, while Kernel.inspect/1
    # prints them in the VM's per-boot order. Building the expectation with inspect/1 here
    # would pass or fail depending on the boot.
    test "keeps a map and its subset, which are distinct items", %{page: page} do
      page
      |> visit(ComprehensionPage)
      |> click_button("Unique with a map and its subset")
      |> assert_text("#result", ~s([%{a: 1, b: 2}, %{a: 1}]))
    end
  end

  describe "reducer" do
    test "accumulates over a single enumerable generator", %{page: page} do
      page
      |> visit(ComprehensionPage)
      |> click_button("Reducer with single generator")
      |> assert_text("#result", "6")
    end

    test "accumulates over a bitstring generator", %{page: page} do
      page
      |> visit(ComprehensionPage)
      |> click_button("Reducer with bitstring generator")
      |> assert_text("#result", "9")
    end

    test "accumulates over multiple enumerable generators", %{page: page} do
      page
      |> visit(ComprehensionPage)
      |> click_button("Reducer with multiple generators")
      |> assert_text("#result", "90")
    end

    test "returns the initial value when the enumerable generator is empty", %{
      page: page
    } do
      page
      |> visit(ComprehensionPage)
      |> click_button("Reducer with empty generator")
      |> assert_text("#result", "100")
    end

    test "returns the initial value when filters reject all items", %{page: page} do
      page
      |> visit(ComprehensionPage)
      |> click_button("Reducer with all-rejecting filter")
      |> assert_text("#result", "200")
    end

    test "filters limit which items update the accumulator", %{page: page} do
      page
      |> visit(ComprehensionPage)
      |> click_button("Reducer with selective filter")
      |> assert_text("#result", "306")
    end

    test "dispatches to the clause matching the accumulator", %{page: page} do
      page
      |> visit(ComprehensionPage)
      |> click_button("Reducer with clause dispatch")
      |> assert_text("#result", "123")
    end

    test "dispatches to the clause whose guards pass", %{page: page} do
      page
      |> visit(ComprehensionPage)
      |> click_button("Reducer with guard dispatch")
      |> assert_text("#result", "33")
    end

    test "reducer clauses can access variables from comprehension outer scope", %{
      page: page
    } do
      page
      |> visit(ComprehensionPage)
      |> click_button("Reducer with outer scope access")
      |> assert_text("#result", "32")
    end

    test "raises CaseClauseError when no clause matches the accumulator", %{page: page} do
      assert_client_error page,
                          CaseClauseError,
                          "no case clause matching:\n\n    0\n",
                          fn ->
                            page
                            |> visit(ComprehensionPage)
                            |> click_button("Reducer with unmatched accumulator")
                          end
    end

    # TODO: expect the BEAM form, %HologramFeatureTests.StructFixture1{name: "acc", value: 6},
    # once struct inspect is implemented (see the "TODO: inspect structs" note on
    # Interpreter.#inspectMap/2 in assets/js/interpreter.mjs). Both sides render structs as
    # plain maps for now - the page inspects with Hologram.Commons.KernelUtils.inspect/1,
    # which mirrors the client, so server and client agree on this text.
    test "matches a struct pattern accumulator", %{page: page} do
      page
      |> visit(ComprehensionPage)
      |> click_button("Reducer with struct accumulator")
      |> assert_text(
        "#result",
        ~s(%{__struct__: HologramFeatureTests.StructFixture1, name: "acc", value: 6})
      )
    end
  end
end
