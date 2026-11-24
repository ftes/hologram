defmodule HologramFeatureTests.Events.ChangeTest do
  use HologramFeatureTests.TestCase, async: true

  alias HologramFeatureTests.Events.Change.Page1
  alias HologramFeatureTests.Events.Change.Page2
  alias HologramFeatureTests.Events.Change.Page3

  test "text input", %{page: page} do
    page
    |> visit(Page1)
    |> fill_in("#text_input_elem", with: "abc text")
    |> assert_text("#result", ~r/\{:text_input, %\{event: %\{value: "abc text"\}\}\}/)
    |> fill_in("#text_input_elem", with: "xyz text")
    |> click_button("Blur")
    |> assert_text("#result", ~r/\{:text_input, %\{event: %\{value: "xyz text"\}\}\}/)
  end

  test "email input", %{page: page} do
    page
    |> visit(Page1)
    |> fill_in("#email_input_elem", with: "abc email")
    |> assert_text("#result", ~r/\{:email_input, %\{event: %\{value: "abc email"\}\}\}/)
    |> fill_in("#email_input_elem", with: "xyz email")
    |> click_button("Blur")
    |> assert_text("#result", ~r/\{:email_input, %\{event: %\{value: "xyz email"\}\}\}/)
  end

  test "textarea", %{page: page} do
    page
    |> visit(Page1)
    |> fill_in("#textarea_elem", with: "abc textarea")
    |> assert_text("#result", ~r/\{:textarea, %\{event: %\{value: "abc textarea"\}\}\}/)
    |> fill_in("#textarea_elem", with: "xyz textarea")
    |> click_button("Blur")
    |> assert_text("#result", ~r/\{:textarea, %\{event: %\{value: "xyz textarea"\}\}\}/)
  end

  test "checkbox, checked to unchecked", %{page: page} do
    page
    |> visit(Page1)
    # Uncheck it since it starts checked
    |> click("#checkbox_elem")
    |> assert_text("#result", ~r/\{:checkbox, %\{event: %\{value: false\}\}\}/)
  end

  test "checkbox, unchecked to checked", %{page: page} do
    page
    |> visit(Page1)
    # Uncheck it first since it starts checked
    |> click("#checkbox_elem")
    # Then check it again
    |> click("#checkbox_elem")
    |> assert_text("#result", ~r/\{:checkbox, %\{event: %\{value: true\}\}\}/)
  end

  test "radio button, unselected to selected", %{page: page} do
    page
    |> visit(Page1)
    # The first radio button starts unselected
    |> click("#radio_elem_1")
    |> assert_text("#result", ~r/\{:radio, %\{event: %\{value: "option_1"\}\}\}/)
    # The action stores the event value in state, so the radio stays selected after the re-render
    |> assert_has("#radio_elem_1:checked")
  end

  test "radio button, changing selection within group", %{page: page} do
    page
    |> visit(Page1)
    # The first radio button starts unselected, so click it first
    |> click("#radio_elem_1")
    |> click("#radio_elem_2")
    |> assert_text("#result", ~r/\{:radio, %\{event: %\{value: "option_2"\}\}\}/)
    # The action stores the event value in state, so the radio stays selected after the re-render
    |> assert_has("#radio_elem_2:checked")
  end

  test "single select, changing selection", %{page: page} do
    page
    |> visit(Page1)
    # Start with option_2 selected
    # Change selection to option_3 (this automatically deselects option_2)
    |> click("#single_select_elem")
    |> select_option("#single_select_elem", "option_3")
    |> assert_text("#result", ~r/\{:single_select, %\{event: %\{value: "option_3"\}\}\}/)
  end

  test "multiple select, adding option", %{page: page} do
    page
    |> visit(Page1)
    # Start with option_2 and option_3 selected
    # Use JavaScript to programmatically select option_1 to add it to the selection
    |> execute_script("""
      const select = document.querySelector("#multiple_select_elem");
      const option1 = select.querySelector("option[value='option_1']");
      option1.selected = true;
      // Programmatic DOM changes don't automatically fire events
      // We need to manually dispatch the change event to trigger Hologram's event handler
      select.dispatchEvent(new Event('change', {bubbles: true}));
    """)
    |> assert_text(
      "#result",
      ~r/\{:multiple_select, %\{event: %\{value: \["option_1", "option_2", "option_3"\]\}\}\}/
    )
  end

  test "multiple select, removing option", %{page: page} do
    page
    |> visit(Page1)
    # Start with option_2 and option_3 selected
    # Use JavaScript to programmatically deselect option_2
    |> execute_script("""
      const select = document.querySelector("#multiple_select_elem");
      const option2 = select.querySelector("option[value='option_2']");
      option2.selected = false;
      // Programmatic DOM changes don't automatically fire events
      // We need to manually dispatch the change event to trigger Hologram's event handler
      select.dispatchEvent(new Event('change', {bubbles: true}));
    """)
    |> assert_text(
      "#result",
      ~r/\{:multiple_select, %\{event: %\{value: \["option_3"\]\}\}\}/
    )
  end

  test "form level change event", %{page: page} do
    page
    |> visit(Page2)
    |> fill_in("form input[name='non_empty_text']", with: "my_text")
    |> click_button("Blur")
    |> assert_text(
      "#result",
      ~s'{:form, %{event: %{"checked_checkbox" => true, "empty_email" => "", "empty_text" => "", "empty_textarea" => "", "non_empty_email" => "my_email", "non_empty_text" => "my_text", "non_empty_textarea" => "my_textarea", "radio_group" => "option_2", "single_select" => "option_3"}}}'
    )
  end

  test "form level change event on a form whose fields hide its properties", %{
    page: page
  } do
    page
    |> visit(Page3)
    |> fill_in("form input[name='localName']", with: "my_text")
    |> click_button("Blur")
    |> assert_text(
      "#result",
      ~s'{:form, %{event: %{"elements" => true, "localName" => "my_text"}}}'
    )
  end
end
