defmodule HologramFeatureTests.Events.SelectTest do
  use HologramFeatureTests.TestCase, async: true
  alias HologramFeatureTests.Events.SelectPage

  defp trigger_select_event_script(elem_id) do
    """
      const elem = document.querySelector("##{elem_id}");
      elem.focus();
      elem.setSelectionRange(6, 15);
      
      const event = new Event("select", {bubbles: true});
      elem.dispatchEvent(event);
      
      return true;
    """
  end

  test "text input", %{page: page} do
    script = trigger_select_event_script("text_input")

    page
    |> visit(SelectPage)
    |> execute_script(script)
    |> assert_text("#result", ~r/\{:text_input, %\{event: %\{value: "am 1 Holo"\}\}\}/)
  end

  test "textarea", %{page: page} do
    script = trigger_select_event_script("textarea")

    page
    |> visit(SelectPage)
    |> execute_script(script)
    |> assert_text("#result", ~r/\{:textarea, %\{event: %\{value: "am 2 Holo"\}\}\}/)
  end
end
