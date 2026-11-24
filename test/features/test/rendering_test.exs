defmodule HologramFeatureTests.RenderingTest do
  use HologramFeatureTests.TestCase, async: true

  alias HologramFeatureTests.Components.Rendering.PropValidationComponent
  alias HologramFeatureTests.Components.Rendering.UndefinedVarComponent
  alias HologramFeatureTests.Rendering.DefaultInitPage
  alias HologramFeatureTests.Rendering.Page1
  alias HologramFeatureTests.Rendering.Page2
  alias HologramFeatureTests.Rendering.Page3
  alias HologramFeatureTests.Rendering.Page4
  alias HologramFeatureTests.Rendering.PropsOnStructPage
  alias HologramFeatureTests.Rendering.PropValidationPage
  alias HologramFeatureTests.Rendering.StateDefaultsPage
  alias HologramFeatureTests.Rendering.UndefinedVarPage

  test "root element without attributes", %{page: page} do
    page
    |> visit(Page1)
    |> assert_has("html")
  end

  test "root element with single attribute", %{page: page} do
    page
    |> visit(Page2)
    |> assert_has("html[attr_1='value_1']")
  end

  test "root element with multiple attributes", %{page: page} do
    page
    |> visit(Page3)
    |> assert_has("html[attr_1='value_1']")
    |> assert_has("html[attr_2='value_2']")
  end

  # The length is what pins the fix. The text is repaired by the client's own render on boot, so it
  # reads correctly either way, but the length was measured on the server and shipped, so it still
  # says what the server saw. Escaped, "a & b < c" would reach the component as "a &amp; b &lt; c"
  # and the count would be 16.
  test "component prop written as text is the string the template wrote", %{page: page} do
    page
    |> visit(Page4)
    |> assert_text("#text", "a & b < c")
    |> assert_text("#length", "9")
  end

  describe "props on the component struct" do
    # The prop is changed after mount and then read in an action. A component that copied the prop
    # into state during init would answer 0 here forever, which is the trap this closes.
    test "action reads the prop the latest render passed", %{page: page} do
      page
      |> visit(PropsOnStructPage, n: 1)
      |> click_button("Increment")
      |> click_button("Increment")
      |> assert_text("#component_1_prop_count", "2")
      |> click("#component_1_read_prop")
      |> assert_text("#component_1_result", "2")
    end

    test "action reads the prop on the first render", %{page: page} do
      page
      |> visit(PropsOnStructPage, n: 1)
      |> click("#component_1_read_prop")
      |> assert_text("#component_1_result", "0")
    end

    # Component 2 is not in the tree when the page loads, so it goes down the client's init/2 path
    # rather than being initialized on the server.
    test "action reads the prop of a component added after load", %{page: page} do
      page
      |> visit(PropsOnStructPage, n: 1)
      |> click_button("Increment")
      |> click_button("Increment")
      |> click_button("Show component 2")
      |> assert_text("#component_2_prop_count", "2")
      |> click("#component_2_read_prop")
      |> assert_text("#component_2_result", "2")
    end

    test "page action reads a URL param", %{page: page} do
      page
      |> visit(PropsOnStructPage, n: 7)
      |> click_button("Read param")
      |> assert_text("#page_result", "7")
    end
  end

  describe "default initialization" do
    # Component 1 is initialized on the server and component 2 on the client, and the component
    # defines neither init/3 nor init/2, so both go through the defaults.
    test "component without init callbacks renders on the server and on the client", %{
      page: page
    } do
      page
      |> visit(DefaultInitPage)
      |> assert_text("#component_1", "first")
      |> click_button("Show component 2")
      |> assert_text("#component_2", "second")
    end
  end

  describe "declared state defaults" do
    test "seed a page's state on the server", %{page: page} do
      page
      |> visit(StateDefaultsPage)
      |> assert_text("#page_greeting", "page default")
    end

    test "seed a layout's state on the server", %{page: page} do
      page
      |> visit(StateDefaultsPage)
      |> assert_text("#layout_greeting", "layout default")
    end

    test "seed the state of a component initialized on the server", %{page: page} do
      page
      |> visit(StateDefaultsPage)
      |> assert_text("#component_1", "server component default")
    end

    # Component 2 isn't in the tree when the page loads, so the client renderer seeds its state.
    test "seed the state of a component initialized on the client", %{page: page} do
      page
      |> visit(StateDefaultsPage)
      |> click_button("Show component 2")
      |> assert_text("#component_2", "client component default")
    end
  end

  describe "prop validation" do
    # The component is reached through a spread, so the compiler can't judge the usage and the
    # client renderer is what enforces the contract.
    test "renders when every prop honours its declaration", %{page: page} do
      page
      |> visit(PropValidationPage)
      |> click_button("Render valid")
      |> assert_text("#prop_validation_result", "my_label / small")
    end

    test "raises when a required prop is missing", %{page: page} do
      expected_msg =
        ~s/component "#{inspect(PropValidationComponent)}" is missing required prop "label", / <>
          ~s/rendered from "#{inspect(PropValidationPage)}"/

      assert_client_error page, Hologram.PropError, expected_msg, fn ->
        page
        |> visit(PropValidationPage)
        |> click_button("Render without required prop")
      end
    end

    test "raises when a prop value is outside its :values list", %{page: page} do
      expected_msg =
        ~s/prop "size" of component "#{inspect(PropValidationComponent)}" must be one of / <>
          ~s/[:small, :large], got: :huge, rendered from "#{inspect(PropValidationPage)}"/

      assert_client_error page, Hologram.PropError, expected_msg, fn ->
        page
        |> visit(PropValidationPage)
        |> click_button("Render with invalid value")
      end
    end
  end

  test "raises when a template uses a var it doesn't have", %{page: page} do
    expected_msg =
      ~s/undefined var @missing in the template of "#{inspect(UndefinedVarComponent)}", / <>
        "available vars: @label"

    assert_client_error page, Hologram.MisuseError, expected_msg, fn ->
      page
      |> visit(UndefinedVarPage)
      |> click_button("Show")
    end
  end
end
