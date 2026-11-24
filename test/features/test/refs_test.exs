defmodule HologramFeatureTests.RefsTest do
  use HologramFeatureTests.TestCase, async: true

  alias HologramFeatureTests.Refs.Page1
  alias HologramFeatureTests.Refs.Page2
  alias HologramFeatureTests.Refs.Page3

  @chained_action_hint "a template declares the ref, but nothing renders it right now. " <>
                         "An element the action's own state change renders is on the page only once the action returns, " <>
                         "so look it up in an action chained with put_action/2"

  describe "JS.element/1" do
    test "returns the element under a ref, for a JS function to act on", %{page: page} do
      page
      |> visit(Page1)
      |> click_button("Focus search")
      |> assert_has("#page_1_search:focus")
    end

    test "returns the element under a tuple ref of a loop item", %{page: page} do
      page
      |> visit(Page1)
      |> click_button("Read item")
      |> assert_text("#page_1_result", "item: Item 2")
    end

    test "returns the document for :document", %{page: page} do
      page
      |> visit(Page1)
      |> click_button("Read document")
      |> assert_text("#page_1_result", "document: HTML")
    end

    test "returns the window for :window", %{page: page} do
      page
      |> visit(Page1)
      |> click_button("Read window")
      |> assert_text("#page_1_result", "window: /refs/1")
    end

    test "returns a native value unchanged", %{page: page} do
      page
      |> visit(Page1)
      |> click_button("Pass native value")
      |> assert_text("#page_1_result", "native value: page_1_search")
    end

    test "returns the element under a ref kept in state and passed to a component as a prop",
         %{page: page} do
      page
      |> visit(Page2)
      |> click_button("Read field")
      |> assert_text("#page_2_result", "field: refs_field")
    end

    test "returns an element of the layout to a page action", %{page: page} do
      page
      |> visit(Page2)
      |> click_button("Read layout header")
      |> assert_text("#page_2_result", "layout header: Refs layout header")
    end

    test "returns, in a chained action, the element the first action's state change rendered",
         %{page: page} do
      page
      |> visit(Page2)
      |> click_button("Show details")
      |> assert_text("#page_2_result", "details: Details text")
    end

    test "returns the element a ref moved to in the last render", %{page: page} do
      page
      |> visit(Page2)
      |> click_button("Read swapped element")
      |> assert_text("#page_2_result", "swapped element: First element")
      |> click_button("Toggle swap")
      |> click_button("Read swapped element")
      |> assert_text("#page_2_result", "swapped element: Second element")
    end

    test "returns the elements of the page a navigation shows", %{page: page} do
      page
      |> visit(Page1)
      |> click_link("Go to page 2")
      |> assert_page(Page2)
      |> click_button("Read note")
      |> assert_text("#page_2_result", "note: Page 2 note")
    end

    # A history restore mounts the page from its snapshot, with no interim patch before its first
    # render.
    test "returns the elements of the page a history Back restores", %{page: page} do
      page
      |> visit(Page1)
      |> click_link("Go to page 2")
      |> assert_page(Page2)
      |> go_back()
      |> assert_page(Page1)
      |> click_button("Read third item")
      |> assert_text("#page_1_result", "third item: Item 3")
    end

    test "raises for a ref a template declares and nothing renders", %{page: page} do
      page = visit(page, Page3)

      assert_client_error page,
                          Hologram.MisuseError,
                          "no element is rendered under the ref :hidden - #{@chained_action_hint}",
                          fn -> click_button(page, "Read hidden") end
    end

    test "raises for an element the action's own state change renders", %{page: page} do
      page = visit(page, Page3)

      assert_client_error page,
                          Hologram.MisuseError,
                          "no element is rendered under the ref :late - #{@chained_action_hint}",
                          fn -> click_button(page, "Show and read late") end
    end

    # The suggestion comes from the refs the page's bundle carries.
    test "raises for a misspelled ref, suggesting the closest one the page declares",
         %{page: page} do
      page = visit(page, Page3)

      assert_client_error page,
                          Hologram.MisuseError,
                          "no element is rendered under the ref :serch - did you mean :search?",
                          fn -> click_button(page, "Read misspelled ref") end
    end
  end

  describe "$ref" do
    # Both refs come from expressions, so the build can't see them clash, and they clash only in
    # the render that follows the action.
    test "raises for two elements under one ref, naming both components", %{page: page} do
      page = visit(page, Page3)

      assert_client_error page,
                          Hologram.MisuseError,
                          "two elements are rendered under the ref :first_paragraph, " <>
                            ~s(one from "HologramFeatureTests.Components.Refs.FirstParagraph" ) <>
                            ~s(and one from "HologramFeatureTests.Components.Refs.SecondParagraph" - ) <>
                            "a ref names one element, so give each element a ref of its own, " <>
                            "like {:first_paragraph, item.id} for the items of a loop",
                          fn -> click_button(page, "Clash refs") end
    end
  end
end
