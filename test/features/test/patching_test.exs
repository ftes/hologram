defmodule HologramFeatureTests.PatchingTest do
  use HologramFeatureTests.TestCase, async: true

  alias HologramFeatureTests.Patching.Page1
  alias HologramFeatureTests.Patching.Page10
  alias HologramFeatureTests.Patching.Page11
  alias HologramFeatureTests.Patching.Page12
  alias HologramFeatureTests.Patching.Page13
  alias HologramFeatureTests.Patching.Page14
  alias HologramFeatureTests.Patching.Page15
  alias HologramFeatureTests.Patching.Page16
  alias HologramFeatureTests.Patching.Page17
  alias HologramFeatureTests.Patching.Page18
  alias HologramFeatureTests.Patching.Page19
  alias HologramFeatureTests.Patching.Page2
  alias HologramFeatureTests.Patching.Page20
  alias HologramFeatureTests.Patching.Page21
  alias HologramFeatureTests.Patching.Page22
  alias HologramFeatureTests.Patching.Page23
  alias HologramFeatureTests.Patching.Page24
  alias HologramFeatureTests.Patching.Page3
  alias HologramFeatureTests.Patching.Page4
  alias HologramFeatureTests.Patching.Page5
  alias HologramFeatureTests.Patching.Page6
  alias HologramFeatureTests.Patching.Page7
  alias HologramFeatureTests.Patching.Page8
  alias HologramFeatureTests.Patching.Page9

  @page20_rows ["row_1", "row_2", "row_3"]

  # Reverses the page's lists, then removes the first row, checking after each that the rows of the
  # given kind of list kept their nodes, their order and their typed values. A typed value on the
  # first and last rows is what a node reused for another item would carry to the wrong row.
  defp assert_rows_follow_their_items(page, page_module, kind) do
    rows = Enum.map(["alpha", "bravo", "charlie"], &"#{kind}_row_#{&1}")

    page
    |> visit(page_module)
    |> assert_text("#result", "alpha, bravo, charlie")
    |> fill_in("##{kind}_input_alpha", with: "typed alpha")
    |> fill_in("##{kind}_input_charlie", with: "typed charlie")
    |> mark_nodes(rows)
    |> click("#reverse")
    |> assert_text("#result", ~r/^charlie, bravo, alpha$/)
    |> assert_script_result(row_ids_script("#{kind}_rows"), Enum.reverse(rows))
    |> assert_input_value("##{kind}_input_alpha", "typed alpha")
    |> assert_input_value("##{kind}_input_charlie", "typed charlie")
    |> assert_script_result(kept_nodes_script(rows), rows)
    |> click("#remove_first")
    |> assert_text("#result", ~r/^bravo, alpha$/)
    |> assert_script_result(row_ids_script("#{kind}_rows"), [
      "#{kind}_row_bravo",
      "#{kind}_row_alpha"
    ])
    |> assert_input_value("##{kind}_input_alpha", "typed alpha")
    |> assert_script_result(
      kept_nodes_script(["#{kind}_row_alpha", "#{kind}_row_bravo"]),
      ["#{kind}_row_alpha", "#{kind}_row_bravo"]
    )
  end

  # Clicked from a script rather than by the driver, so the button never takes focus itself: any
  # focus change that follows is then the page's doing, which is the thing under test.
  defp click_by_script(page, id) do
    execute_script(page, ~s|document.getElementById("#{id}").click();|)
  end

  defp focus_by_script(page, id) do
    execute_script(page, ~s|document.getElementById("#{id}").focus();|)
  end

  # The given elements whose node is still the one mark_nodes/2 tagged.
  defp kept_nodes_script(ids) do
    """
    return #{inspect(ids)}.filter((id) => document.getElementById(id).__probe === id);
    """
  end

  # Each element's node is tagged with a property the diff never reads, so it lives exactly as long
  # as the DOM node does.
  defp mark_nodes(page, ids) do
    execute_script(page, """
    #{inspect(ids)}.forEach((id) => {
      document.getElementById(id).__probe = id;
    });
    """)
  end

  # The ids of a list's rows, in document order.
  defp row_ids_script(list_id) do
    ~s|return [...document.querySelectorAll("##{list_id} > li")].map((li) => li.id);|
  end

  # The given rows whose node is still the one its script stamped when it was inserted.
  defp stamped_rows_script(ids) do
    """
    return #{inspect(ids)}.filter((id) => document.getElementById(id).__stamped === true);
    """
  end

  describe "root element attributes patching" do
    test "after action", %{page: page} do
      page
      |> visit(Page1)
      |> refute_has("html[attr_1]")
      |> refute_has("html[attr_2]")
      |> click_button("Add root elem attr 2")
      |> refute_has("html[attr_1]")
      |> assert_has("html[attr_2='value_2a']")
      |> click_button("Add root elem attr 1")
      |> assert_has("html[attr_1='value_1a']")
      |> assert_has("html[attr_2='value_2a']")
      |> click_button("Change root elem attr 2")
      |> assert_has("html[attr_1='value_1a']")
      |> assert_has("html[attr_2='value_2b']")
      |> click_button("Change root elem attr 1")
      |> assert_has("html[attr_1='value_1b']")
      |> assert_has("html[attr_2='value_2b']")
      |> click_button("Remove root elem attr 2")
      |> assert_has("html[attr_1='value_1b']")
      |> refute_has("html[attr_2]")
      |> click_button("Remove root elem attr 1")
      |> refute_has("html[attr_1]")
      |> refute_has("html[attr_2]")
    end

    test "after navigation", %{page: page} do
      page
      |> visit(Page1)
      |> click_button("Add root elem attr 1")
      |> click_button("Add root elem attr 2")
      |> assert_has("html[attr_1='value_1a']")
      |> assert_has("html[attr_2='value_2a']")
      |> click_link("Page 2 link")
      |> assert_page(Page2)
      |> refute_has("html[attr_1]")
      |> refute_has("html[attr_2]")
      |> assert_has("html[attr_3='value_3']")
    end
  end

  describe "body element attributes patching" do
    test "after action", %{page: page} do
      page
      |> visit(Page6)
      |> refute_has("body[attr_1]")
      |> refute_has("body[attr_2]")
      |> click_button("Add body elem attr 2")
      |> refute_has("body[attr_1]")
      |> assert_has("body[attr_2='value_2a']")
      |> click_button("Add body elem attr 1")
      |> assert_has("body[attr_1='value_1a']")
      |> assert_has("body[attr_2='value_2a']")
      |> click_button("Change body elem attr 2")
      |> assert_has("body[attr_1='value_1a']")
      |> assert_has("body[attr_2='value_2b']")
      |> click_button("Change body elem attr 1")
      |> assert_has("body[attr_1='value_1b']")
      |> assert_has("body[attr_2='value_2b']")
      |> click_button("Remove body elem attr 2")
      |> assert_has("body[attr_1='value_1b']")
      |> refute_has("body[attr_2]")
      |> click_button("Remove body elem attr 1")
      |> refute_has("body[attr_1]")
      |> refute_has("body[attr_2]")
    end

    test "after navigation", %{page: page} do
      page
      |> visit(Page6)
      |> click_button("Add body elem attr 1")
      |> click_button("Add body elem attr 2")
      |> assert_has("body[attr_1='value_1a']")
      |> assert_has("body[attr_2='value_2a']")
      |> click_link("Page 7 link")
      |> assert_page(Page7)
      |> refute_has("body[attr_1]")
      |> refute_has("body[attr_2]")
      |> assert_has("body[attr_3='value_3']")
    end
  end

  describe "class attribute in root element patching" do
    test "has class initially, changes to different class", %{page: page} do
      page
      |> visit(Page3)
      |> click_button("Change to class 2")
      |> assert_has("html[class='my_class_2']")
    end

    test "has class initially, class is removed", %{page: page} do
      page
      |> visit(Page3)
      |> click_button("Remove class")
      |> refute_has("html[class]")
    end

    test "no class initially, class is added", %{page: page} do
      page
      |> visit(Page4)
      |> click_button("Add class")
      |> assert_has("html[class='my_class']")
    end

    test "has class after update, changes to different class", %{page: page} do
      page
      |> visit(Page3)
      |> click_button("Change to class 2")
      |> assert_has("html[class='my_class_2']")
      |> click_button("Change to class 3")
      |> assert_has("html[class='my_class_3']")
    end

    test "has class after update, class is removed", %{page: page} do
      page
      |> visit(Page3)
      |> click_button("Change to class 2")
      |> assert_has("html[class='my_class_2']")
      |> click_button("Remove class")
      |> refute_has("html[class]")
    end

    test "no class after update, class is added", %{page: page} do
      page
      |> visit(Page3)
      |> click_button("Remove class")
      |> refute_has("html[class]")
      |> click_button("Change to class 2")
      |> assert_has("html[class='my_class_2']")
    end
  end

  describe "class attribute in body element patching" do
    test "has class initially, changes to different class", %{page: page} do
      page
      |> visit(Page8)
      |> click_button("Change to class 2")
      |> assert_has("body[class='my_class_2']")
    end

    test "has class initially, class is removed", %{page: page} do
      page
      |> visit(Page8)
      |> click_button("Remove class")
      |> refute_has("body[class]")
    end

    test "no class initially, class is added", %{page: page} do
      page
      |> visit(Page9)
      |> click_button("Add class")
      |> assert_has("body[class='my_class']")
    end

    test "has class after update, changes to different class", %{page: page} do
      page
      |> visit(Page8)
      |> click_button("Change to class 2")
      |> assert_has("body[class='my_class_2']")
      |> click_button("Change to class 3")
      |> assert_has("body[class='my_class_3']")
    end

    test "has class after update, class is removed", %{page: page} do
      page
      |> visit(Page8)
      |> click_button("Change to class 2")
      |> assert_has("body[class='my_class_2']")
      |> click_button("Remove class")
      |> refute_has("body[class]")
    end

    test "no class after update, class is added", %{page: page} do
      page
      |> visit(Page8)
      |> click_button("Remove class")
      |> refute_has("body[class]")
      |> click_button("Change to class 2")
      |> assert_has("body[class='my_class_2']")
    end
  end

  describe "form elements value patching" do
    # We're testing different combinations of specific user operations:
    # 1) change programmatically to a non-empty value that is the same as the last programmatic value
    # 2) change programmatically to a non-empty value that is different than the last programmatic value
    # 3) change programmatically to an empty value when the last programmatic value was also empty
    # 4) change programmatically to an empty value when the last programmatic value was not empty
    # 5) change manually to a non-empty value that is the same as the last programmatic value
    # 6) change manually to a non-empty value that is different than the last programmatic value
    # 7) change manually to an empty value when the last programmatic value was also empty
    # 8) change manually to an empty value when the last programmatic value was not empty

    test "text input value patching (without state synchronization)", %{page: page} do
      page
      |> visit(Page5)
      |> assert_input_value("#text_input", "initial text")
      |> refute_has("#text_input[value]")
      # --- Setup A: establish baseline programmatic value
      |> click_button("Update Text 1")
      |> assert_input_value("#text_input", "programmatic 1")
      |> refute_has("#text_input[value]")
      # --- Group 1 (Cond 6): manual non-empty, different from last prog
      |> fill_in("#text_input", with: "manual 1")
      |> assert_input_value("#text_input", "manual 1")
      |> refute_has("#text_input[value]")
      # --- Group 2 (Cond 1): prog non-empty, same as last prog
      |> click_button("Update Text 1")
      |> assert_input_value("#text_input", "programmatic 1")
      |> refute_has("#text_input[value]")
      # --- Group 3 (Cond 2): prog non-empty, different from last prog
      |> click_button("Update Text 2")
      |> assert_input_value("#text_input", "programmatic 2")
      |> refute_has("#text_input[value]")
      # --- Setup B: switch to a different manual value
      |> fill_in("#text_input", with: "manual 2")
      |> assert_input_value("#text_input", "manual 2")
      |> refute_has("#text_input[value]")
      # --- Group 4 (Cond 5): manual non-empty, same as last prog
      |> fill_in("#text_input", with: "programmatic 2")
      |> assert_input_value("#text_input", "programmatic 2")
      |> refute_has("#text_input[value]")
      # --- Group 5 (Cond 4): prog empty, last prog was not empty
      |> click_button("Clear All State")
      |> assert_input_value("#text_input", "")
      |> refute_has("#text_input[value]")
      # --- Setup C: switch to a different manual value
      |> fill_in("#text_input", with: "manual 3")
      |> assert_input_value("#text_input", "manual 3")
      |> refute_has("#text_input[value]")
      # --- Group 6 (Cond 7): manual empty, last prog was also empty
      |> fill_in("#text_input", with: "")
      |> assert_input_value("#text_input", "")
      |> refute_has("#text_input[value]")
      # --- Setup D: switch to a different manual value
      |> fill_in("#text_input", with: "manual 4")
      |> assert_input_value("#text_input", "manual 4")
      |> refute_has("#text_input[value]")
      # --- Group 7 (Cond 3): prog empty, last prog was also empty
      |> click_button("Clear All State")
      |> assert_input_value("#text_input", "")
      |> refute_has("#text_input[value]")
      # --- Setup E: set non-empty programmatic value
      |> click_button("Update Text 1")
      |> assert_input_value("#text_input", "programmatic 1")
      |> refute_has("#text_input[value]")
      # --- Group 8 (Cond 8): manual empty, last prog was not empty
      |> fill_in("#text_input", with: "")
      |> assert_input_value("#text_input", "")
      |> refute_has("#text_input[value]")
    end

    test "text input value patching (with state synchronization)", %{page: page} do
      page
      |> visit(Page10)
      |> assert_input_value("#text_input", "initial text")
      |> assert_text("#text_result", "initial text")
      |> refute_has("#text_input[value]")
      # --- Setup A: establish baseline programmatic value
      |> click_button("Update Text 1")
      |> assert_input_value("#text_input", "programmatic 1")
      |> assert_text("#text_result", "programmatic 1")
      |> refute_has("#text_input[value]")
      # --- Group 1 (Cond 6): manual non-empty, different from last prog
      |> fill_in("#text_input", with: "manual 1")
      |> assert_input_value("#text_input", "manual 1")
      |> assert_text("#text_result", "manual 1")
      |> refute_has("#text_input[value]")
      # --- Group 2 (Cond 1): prog non-empty, same as last prog
      |> click_button("Update Text 1")
      |> assert_input_value("#text_input", "programmatic 1")
      |> assert_text("#text_result", "programmatic 1")
      |> refute_has("#text_input[value]")
      # --- Group 3 (Cond 2): prog non-empty, different from last prog
      |> click_button("Update Text 2")
      |> assert_input_value("#text_input", "programmatic 2")
      |> assert_text("#text_result", "programmatic 2")
      |> refute_has("#text_input[value]")
      # --- Setup B: switch to a different manual value
      |> fill_in("#text_input", with: "manual 2")
      |> assert_input_value("#text_input", "manual 2")
      |> assert_text("#text_result", "manual 2")
      |> refute_has("#text_input[value]")
      # --- Group 4 (Cond 5): manual non-empty, same as last prog
      |> fill_in("#text_input", with: "programmatic 2")
      |> assert_input_value("#text_input", "programmatic 2")
      |> assert_text("#text_result", "programmatic 2")
      |> refute_has("#text_input[value]")
      # --- Group 5 (Cond 4): prog empty, last prog was not empty
      |> click_button("Clear All State")
      |> assert_input_value("#text_input", "")
      |> assert_text("#text_result", "")
      |> refute_has("#text_input[value]")
      # --- Setup C: switch to a different manual value
      |> fill_in("#text_input", with: "manual 3")
      |> assert_input_value("#text_input", "manual 3")
      |> assert_text("#text_result", "manual 3")
      |> refute_has("#text_input[value]")
      # --- Group 6 (Cond 7): manual empty, last prog was also empty
      |> fill_in("#text_input", with: "")
      |> assert_input_value("#text_input", "")
      |> assert_text("#text_result", "")
      |> refute_has("#text_input[value]")
      # --- Setup D: switch to a different manual value
      |> fill_in("#text_input", with: "manual 4")
      |> assert_input_value("#text_input", "manual 4")
      |> assert_text("#text_result", "manual 4")
      |> refute_has("#text_input[value]")
      # --- Group 7 (Cond 3): prog empty, last prog was also empty
      |> click_button("Clear All State")
      |> assert_input_value("#text_input", "")
      |> assert_text("#text_result", "")
      |> refute_has("#text_input[value]")
      # --- Setup E: set non-empty programmatic value
      |> click_button("Update Text 1")
      |> assert_input_value("#text_input", "programmatic 1")
      |> assert_text("#text_result", "programmatic 1")
      |> refute_has("#text_input[value]")
      # --- Group 8 (Cond 8): manual empty, last prog was not empty
      |> fill_in("#text_input", with: "")
      |> assert_input_value("#text_input", "")
      |> assert_text("#text_result", "")
      |> refute_has("#text_input[value]")
    end

    test "email input value patching (without state synchronization)", %{page: page} do
      page
      |> visit(Page5)
      |> assert_input_value("#email_input", "initial email")
      |> refute_has("#email_input[value]")
      # --- Setup A: establish baseline programmatic value
      |> click_button("Update Email 1")
      |> assert_input_value("#email_input", "programmatic 1")
      |> refute_has("#email_input[value]")
      # --- Group 1 (Cond 6): manual non-empty, different from last prog
      |> fill_in("#email_input", with: "manual 1")
      |> assert_input_value("#email_input", "manual 1")
      |> refute_has("#email_input[value]")
      # --- Group 2 (Cond 1): prog non-empty, same as last prog
      |> click_button("Update Email 1")
      |> assert_input_value("#email_input", "programmatic 1")
      |> refute_has("#email_input[value]")
      # --- Group 3 (Cond 2): prog non-empty, different from last prog
      |> click_button("Update Email 2")
      |> assert_input_value("#email_input", "programmatic 2")
      |> refute_has("#email_input[value]")
      # --- Setup B: switch to a different manual value
      |> fill_in("#email_input", with: "manual 2")
      |> assert_input_value("#email_input", "manual 2")
      |> refute_has("#email_input[value]")
      # --- Group 4 (Cond 5): manual non-empty, same as last prog
      |> fill_in("#email_input", with: "programmatic 2")
      |> assert_input_value("#email_input", "programmatic 2")
      |> refute_has("#email_input[value]")
      # --- Group 5 (Cond 4): prog empty, last prog was not empty
      |> click_button("Clear All State")
      |> assert_input_value("#email_input", "")
      |> refute_has("#email_input[value]")
      # --- Setup C: switch to a different manual value
      |> fill_in("#email_input", with: "manual 3")
      |> assert_input_value("#email_input", "manual 3")
      |> refute_has("#email_input[value]")
      # --- Group 6 (Cond 7): manual empty, last prog was also empty
      |> fill_in("#email_input", with: "")
      |> assert_input_value("#email_input", "")
      |> refute_has("#email_input[value]")
      # --- Setup D: switch to a different manual value
      |> fill_in("#email_input", with: "manual 4")
      |> assert_input_value("#email_input", "manual 4")
      |> refute_has("#email_input[value]")
      # --- Group 7 (Cond 3): prog empty, last prog was also empty
      |> click_button("Clear All State")
      |> assert_input_value("#email_input", "")
      |> refute_has("#email_input[value]")
      # --- Setup E: set non-empty programmatic value
      |> click_button("Update Email 1")
      |> assert_input_value("#email_input", "programmatic 1")
      |> refute_has("#email_input[value]")
      # --- Group 8 (Cond 8): manual empty, last prog was not empty
      |> fill_in("#email_input", with: "")
      |> assert_input_value("#email_input", "")
      |> refute_has("#email_input[value]")
    end

    test "email input value patching (with state synchronization)", %{page: page} do
      page
      |> visit(Page10)
      |> assert_input_value("#email_input", "initial email")
      |> assert_text("#email_result", "initial email")
      |> refute_has("#email_input[value]")
      # --- Setup A: establish baseline programmatic value
      |> click_button("Update Email 1")
      |> assert_input_value("#email_input", "programmatic 1")
      |> assert_text("#email_result", "programmatic 1")
      |> refute_has("#email_input[value]")
      # --- Group 1 (Cond 6): manual non-empty, different from last prog
      |> fill_in("#email_input", with: "manual 1")
      |> assert_input_value("#email_input", "manual 1")
      |> assert_text("#email_result", "manual 1")
      |> refute_has("#email_input[value]")
      # --- Group 2 (Cond 1): prog non-empty, same as last prog
      |> click_button("Update Email 1")
      |> assert_input_value("#email_input", "programmatic 1")
      |> assert_text("#email_result", "programmatic 1")
      |> refute_has("#email_input[value]")
      # --- Group 3 (Cond 2): prog non-empty, different from last prog
      |> click_button("Update Email 2")
      |> assert_input_value("#email_input", "programmatic 2")
      |> assert_text("#email_result", "programmatic 2")
      |> refute_has("#email_input[value]")
      # --- Setup B: switch to a different manual value
      |> fill_in("#email_input", with: "manual 2")
      |> assert_input_value("#email_input", "manual 2")
      |> assert_text("#email_result", "manual 2")
      |> refute_has("#email_input[value]")
      # --- Group 4 (Cond 5): manual non-empty, same as last prog
      |> fill_in("#email_input", with: "programmatic 2")
      |> assert_input_value("#email_input", "programmatic 2")
      |> assert_text("#email_result", "programmatic 2")
      |> refute_has("#email_input[value]")
      # --- Group 5 (Cond 4): prog empty, last prog was not empty
      |> click_button("Clear All State")
      |> assert_input_value("#email_input", "")
      |> assert_text("#email_result", "")
      |> refute_has("#email_input[value]")
      # --- Setup C: switch to a different manual value
      |> fill_in("#email_input", with: "manual 3")
      |> assert_input_value("#email_input", "manual 3")
      |> assert_text("#email_result", "manual 3")
      |> refute_has("#email_input[value]")
      # --- Group 6 (Cond 7): manual empty, last prog was also empty
      |> fill_in("#email_input", with: "")
      |> assert_input_value("#email_input", "")
      |> assert_text("#email_result", "")
      |> refute_has("#email_input[value]")
      # --- Setup D: switch to a different manual value
      |> fill_in("#email_input", with: "manual 4")
      |> assert_input_value("#email_input", "manual 4")
      |> assert_text("#email_result", "manual 4")
      |> refute_has("#email_input[value]")
      # --- Group 7 (Cond 3): prog empty, last prog was also empty
      |> click_button("Clear All State")
      |> assert_input_value("#email_input", "")
      |> assert_text("#email_result", "")
      |> refute_has("#email_input[value]")
      # --- Setup E: set non-empty programmatic value
      |> click_button("Update Email 1")
      |> assert_input_value("#email_input", "programmatic 1")
      |> assert_text("#email_result", "programmatic 1")
      |> refute_has("#email_input[value]")
      # --- Group 8 (Cond 8): manual empty, last prog was not empty
      |> fill_in("#email_input", with: "")
      |> assert_input_value("#email_input", "")
      |> assert_text("#email_result", "")
      |> refute_has("#email_input[value]")
    end

    test "textarea value patching (without state synchronization)", %{page: page} do
      page
      |> visit(Page5)
      |> assert_input_value("#textarea", "initial textarea")
      |> refute_has("#textarea[value]")
      # --- Setup A: establish baseline programmatic value
      |> click_button("Update Textarea 1")
      |> assert_input_value("#textarea", "programmatic 1")
      |> refute_has("#textarea[value]")
      # --- Group 1 (Cond 6): manual non-empty, different from last prog
      |> fill_in("#textarea", with: "manual 1")
      |> assert_input_value("#textarea", "manual 1")
      |> refute_has("#textarea[value]")
      # --- Group 2 (Cond 1): prog non-empty, same as last prog
      |> click_button("Update Textarea 1")
      |> assert_input_value("#textarea", "programmatic 1")
      |> refute_has("#textarea[value]")
      # --- Group 3 (Cond 2): prog non-empty, different from last prog
      |> click_button("Update Textarea 2")
      |> assert_input_value("#textarea", "programmatic 2")
      |> refute_has("#textarea[value]")
      # --- Setup B: switch to a different manual value
      |> fill_in("#textarea", with: "manual 2")
      |> assert_input_value("#textarea", "manual 2")
      |> refute_has("#textarea[value]")
      # --- Group 4 (Cond 5): manual non-empty, same as last prog
      |> fill_in("#textarea", with: "programmatic 2")
      |> assert_input_value("#textarea", "programmatic 2")
      |> refute_has("#textarea[value]")
      # --- Group 5 (Cond 4): prog empty, last prog was not empty
      |> click_button("Clear All State")
      |> assert_input_value("#textarea", "")
      |> refute_has("#textarea[value]")
      # --- Setup C: switch to a different manual value
      |> fill_in("#textarea", with: "manual 3")
      |> assert_input_value("#textarea", "manual 3")
      |> refute_has("#textarea[value]")
      # --- Group 6 (Cond 7): manual empty, last prog was also empty
      |> fill_in("#textarea", with: "")
      |> assert_input_value("#textarea", "")
      |> refute_has("#textarea[value]")
      # --- Setup D: switch to a different manual value
      |> fill_in("#textarea", with: "manual 4")
      |> assert_input_value("#textarea", "manual 4")
      |> refute_has("#textarea[value]")
      # --- Group 7 (Cond 3): prog empty, last prog was also empty
      |> click_button("Clear All State")
      |> assert_input_value("#textarea", "")
      |> refute_has("#textarea[value]")
      # --- Setup E: set non-empty programmatic value
      |> click_button("Update Textarea 1")
      |> assert_input_value("#textarea", "programmatic 1")
      |> refute_has("#textarea[value]")
      # --- Group 8 (Cond 8): manual empty, last prog was not empty
      |> fill_in("#textarea", with: "")
      |> assert_input_value("#textarea", "")
      |> refute_has("#textarea[value]")
    end

    test "textarea value patching (with state synchronization)", %{page: page} do
      page
      |> visit(Page10)
      |> assert_input_value("#textarea", "initial textarea")
      |> assert_text("#textarea_result", "initial textarea")
      |> refute_has("#textarea[value]")
      # --- Setup A: establish baseline programmatic value
      |> click_button("Update Textarea 1")
      |> assert_input_value("#textarea", "programmatic 1")
      |> assert_text("#textarea_result", "programmatic 1")
      |> refute_has("#textarea[value]")
      # --- Group 1 (Cond 6): manual non-empty, different from last prog
      |> fill_in("#textarea", with: "manual 1")
      |> assert_input_value("#textarea", "manual 1")
      |> assert_text("#textarea_result", "manual 1")
      |> refute_has("#textarea[value]")
      # --- Group 2 (Cond 1): prog non-empty, same as last prog
      |> click_button("Update Textarea 1")
      |> assert_input_value("#textarea", "programmatic 1")
      |> assert_text("#textarea_result", "programmatic 1")
      |> refute_has("#textarea[value]")
      # --- Group 3 (Cond 2): prog non-empty, different from last prog
      |> click_button("Update Textarea 2")
      |> assert_input_value("#textarea", "programmatic 2")
      |> assert_text("#textarea_result", "programmatic 2")
      |> refute_has("#textarea[value]")
      # --- Setup B: switch to a different manual value
      |> fill_in("#textarea", with: "manual 2")
      |> assert_input_value("#textarea", "manual 2")
      |> assert_text("#textarea_result", "manual 2")
      |> refute_has("#textarea[value]")
      # --- Group 4 (Cond 5): manual non-empty, same as last prog
      |> fill_in("#textarea", with: "programmatic 2")
      |> assert_input_value("#textarea", "programmatic 2")
      |> assert_text("#textarea_result", "programmatic 2")
      |> refute_has("#textarea[value]")
      # --- Group 5 (Cond 4): prog empty, last prog was not empty
      |> click_button("Clear All State")
      |> assert_input_value("#textarea", "")
      |> assert_text("#textarea_result", "")
      |> refute_has("#textarea[value]")
      # --- Setup C: switch to a different manual value
      |> fill_in("#textarea", with: "manual 3")
      |> assert_input_value("#textarea", "manual 3")
      |> assert_text("#textarea_result", "manual 3")
      |> refute_has("#textarea[value]")
      # --- Group 6 (Cond 7): manual empty, last prog was also empty
      |> fill_in("#textarea", with: "")
      |> assert_input_value("#textarea", "")
      |> assert_text("#textarea_result", "")
      |> refute_has("#textarea[value]")
      # --- Setup D: switch to a different manual value
      |> fill_in("#textarea", with: "manual 4")
      |> assert_input_value("#textarea", "manual 4")
      |> assert_text("#textarea_result", "manual 4")
      |> refute_has("#textarea[value]")
      # --- Group 7 (Cond 3): prog empty, last prog was also empty
      |> click_button("Clear All State")
      |> assert_input_value("#textarea", "")
      |> assert_text("#textarea_result", "")
      |> refute_has("#textarea[value]")
      # --- Setup E: set non-empty programmatic value
      |> click_button("Update Textarea 1")
      |> assert_input_value("#textarea", "programmatic 1")
      |> assert_text("#textarea_result", "programmatic 1")
      |> refute_has("#textarea[value]")
      # --- Group 8 (Cond 8): manual empty, last prog was not empty
      |> fill_in("#textarea", with: "")
      |> assert_input_value("#textarea", "")
      |> assert_text("#textarea_result", "")
      |> refute_has("#textarea[value]")
    end

    @tag timeout: 70_000
    test "checkbox checked patching", %{page: page} do
      # We're testing different combinations of specific user operations for checkboxes:
      # 1) change programmatically to checked when the last programmatic value was also checked
      # 2) change programmatically to checked when the last programmatic value was unchecked
      # 3) change programmatically to unchecked when the last programmatic value was also unchecked
      # 4) change programmatically to unchecked when the last programmatic value was checked
      # 5) change manually to checked when the last programmatic value was also checked
      # 6) change manually to checked when the last programmatic value was unchecked
      # 7) change manually to unchecked when the last programmatic value was also unchecked
      # 8) change manually to unchecked when the last programmatic value was checked

      # credo:disable-for-lines:58 Credo.Check.Design.DuplicatedCode
      page
      |> visit(Page5)
      |> assert_has("#checkbox:checked")
      |> refute_has("#checkbox[checked]")
      # --- Setup A: establish baseline programmatic state (unchecked)
      |> click_button("Uncheck Checkbox")
      |> refute_has("#checkbox:checked")
      |> refute_has("#checkbox[checked]")
      # --- Group 1 (Cond 6): manual checked, different from last prog (unchecked)
      |> click("#checkbox")
      |> assert_has("#checkbox:checked")
      |> refute_has("#checkbox[checked]")
      # --- Group 2 (Cond 3): prog unchecked, same as last prog (unchecked)
      |> click_button("Uncheck Checkbox")
      |> refute_has("#checkbox:checked")
      |> refute_has("#checkbox[checked]")
      # --- Group 3 (Cond 2): prog checked, different from last prog (unchecked)
      |> click_button("Check Checkbox")
      |> assert_has("#checkbox:checked")
      |> refute_has("#checkbox[checked]")
      # --- Setup B: manual change to different state (unchecked)
      |> click("#checkbox")
      |> refute_has("#checkbox:checked")
      |> refute_has("#checkbox[checked]")
      # --- Group 4 (Cond 5): manual checked, same as last prog (checked)
      |> click("#checkbox")
      |> assert_has("#checkbox:checked")
      |> refute_has("#checkbox[checked]")
      # --- Group 5 (Cond 1): prog checked, same as last prog (checked)
      |> click_button("Check Checkbox")
      |> assert_has("#checkbox:checked")
      |> refute_has("#checkbox[checked]")
      # --- Setup C: switch to unchecked programmatically
      |> click_button("Uncheck Checkbox")
      |> refute_has("#checkbox:checked")
      |> refute_has("#checkbox[checked]")
      # --- Group 6 (Cond 7): manual unchecked, same as last prog (unchecked)
      |> click("#checkbox")
      |> assert_has("#checkbox:checked")
      |> click("#checkbox")
      |> refute_has("#checkbox:checked")
      |> refute_has("#checkbox[checked]")
      # --- Setup D: set programmatic state to checked for next test
      |> click_button("Check Checkbox")
      |> assert_has("#checkbox:checked")
      |> refute_has("#checkbox[checked]")
      # --- Group 7 (Cond 4): prog unchecked, different from last prog (checked)
      |> click_button("Uncheck Checkbox")
      |> refute_has("#checkbox:checked")
      |> refute_has("#checkbox[checked]")
      # --- Setup E: set programmatic state to checked for condition 8
      |> click_button("Check Checkbox")
      |> assert_has("#checkbox:checked")
      |> refute_has("#checkbox[checked]")
      # --- Group 8 (Cond 8): manual unchecked, different from last prog (checked)
      |> click("#checkbox")
      |> refute_has("#checkbox:checked")
      |> refute_has("#checkbox[checked]")
    end

    @tag timeout: 100_000
    test "radio checked patching", %{page: page} do
      # We're testing different combinations of specific user operations for radio buttons:
      # 1) change programmatically to a non-empty value that is the same as the last programmatic value
      # 2) change programmatically to a non-empty value that is different than the last programmatic value
      # 3) change programmatically to an empty value when the last programmatic value was also empty
      # 4) change programmatically to an empty value when the last programmatic value was not empty
      # 5) change manually to a non-empty value that is the same as the last programmatic value
      # 6) change manually to a non-empty value that is different than the last programmatic value

      # credo:disable-for-lines:60 Credo.Check.Design.DuplicatedCode
      page
      |> visit(Page5)
      |> refute_has("#radio_option_1:checked")
      |> assert_has("#radio_option_2:checked")
      |> refute_has("#radio_option_1[checked]")
      |> refute_has("#radio_option_2[checked]")
      # --- Setup A: establish baseline programmatic value
      |> click_button("Select Radio Option 1")
      |> assert_has("#radio_option_1:checked")
      |> refute_has("#radio_option_2:checked")
      |> refute_has("#radio_option_1[checked]")
      |> refute_has("#radio_option_2[checked]")
      # --- Group 1 (Cond 6): manual non-empty, different from last prog
      |> click("#radio_option_2")
      |> refute_has("#radio_option_1:checked")
      |> assert_has("#radio_option_2:checked")
      |> refute_has("#radio_option_1[checked]")
      |> refute_has("#radio_option_2[checked]")
      # --- Group 2 (Cond 1): prog non-empty, same as last prog (option_1)
      |> click_button("Select Radio Option 1")
      |> assert_has("#radio_option_1:checked")
      |> refute_has("#radio_option_2:checked")
      |> refute_has("#radio_option_1[checked]")
      |> refute_has("#radio_option_2[checked]")
      # --- Group 3 (Cond 2): prog non-empty, different from last prog
      |> click_button("Select Radio Option 2")
      |> refute_has("#radio_option_1:checked")
      |> assert_has("#radio_option_2:checked")
      |> refute_has("#radio_option_1[checked]")
      |> refute_has("#radio_option_2[checked]")
      # --- Setup B: switch to a different manual value
      |> click("#radio_option_1")
      |> assert_has("#radio_option_1:checked")
      |> refute_has("#radio_option_2:checked")
      |> refute_has("#radio_option_1[checked]")
      |> refute_has("#radio_option_2[checked]")
      # --- Group 4 (Cond 5): manual non-empty, same as last prog
      |> click("#radio_option_2")
      |> refute_has("#radio_option_1:checked")
      |> assert_has("#radio_option_2:checked")
      |> refute_has("#radio_option_1[checked]")
      |> refute_has("#radio_option_2[checked]")
      # --- Group 5 (Cond 4): prog empty, last prog was not empty
      |> click_button("Clear Radio")
      |> refute_has("#radio_option_1:checked")
      |> refute_has("#radio_option_2:checked")
      |> refute_has("#radio_option_1[checked]")
      |> refute_has("#radio_option_2[checked]")
      # --- Setup C: switch to a different manual value
      |> click("#radio_option_1")
      |> assert_has("#radio_option_1:checked")
      |> refute_has("#radio_option_2:checked")
      |> refute_has("#radio_option_1[checked]")
      |> refute_has("#radio_option_2[checked]")
      # --- Group 6 (Cond 3): prog empty, last prog was also empty
      |> click_button("Clear Radio")
      |> refute_has("#radio_option_1:checked")
      |> refute_has("#radio_option_2:checked")
      |> refute_has("#radio_option_1[checked]")
      |> refute_has("#radio_option_2[checked]")
    end

    @tag timeout: 100_000
    test "select selected patching", %{page: page} do
      # We're testing different combinations of specific user operations for selects:
      # 1) change programmatically to a non-empty value that is the same as the last programmatic value
      # 2) change programmatically to a non-empty value that is different than the last programmatic value
      # 3) change programmatically to an empty value when the last programmatic value was also empty
      # 4) change programmatically to an empty value when the last programmatic value was not empty
      # 5) change manually to a non-empty value that is the same as the last programmatic value
      # 6) change manually to a non-empty value that is different than the last programmatic value

      # credo:disable-for-lines:60 Credo.Check.Design.DuplicatedCode
      page
      |> visit(Page5)
      |> assert_input_value("#select", "option_2")
      |> assert_none("#select option[selected]")
      # --- Setup A: establish baseline programmatic value
      |> click_button("Select Select Option 1")
      |> assert_input_value("#select", "option_1")
      |> assert_none("#select option[selected]")
      # --- Group 1 (Cond 6): manual non-empty, different from last prog
      |> select_option("#select", "option_2")
      |> assert_input_value("#select", "option_2")
      |> assert_none("#select option[selected]")
      # --- Group 2 (Cond 1): prog non-empty, same as last prog (option_1)
      |> click_button("Select Select Option 1")
      |> assert_input_value("#select", "option_1")
      |> assert_none("#select option[selected]")
      # --- Group 3 (Cond 2): prog non-empty, different from last prog
      |> click_button("Select Select Option 2")
      |> assert_input_value("#select", "option_2")
      |> assert_none("#select option[selected]")
      # --- Setup B: switch to a different manual value
      |> select_option("#select", "option_1")
      |> assert_input_value("#select", "option_1")
      |> assert_none("#select option[selected]")
      # --- Group 4 (Cond 5): manual non-empty, same as last prog
      |> select_option("#select", "option_2")
      |> assert_input_value("#select", "option_2")
      |> assert_none("#select option[selected]")
      # --- Group 5 (Cond 4): prog empty, last prog was not empty
      |> click_button("Clear Select")
      |> assert_input_value("#select", "")
      |> assert_none("#select option[selected]")
      # --- Setup C: switch to a different manual value
      |> select_option("#select", "option_1")
      |> assert_input_value("#select", "option_1")
      |> assert_none("#select option[selected]")
      # --- Group 6 (Cond 3): prog empty, last prog was also empty
      |> click_button("Clear Select")
      |> assert_input_value("#select", "")
      |> assert_none("#select option[selected]")
    end
  end

  describe "sibling identity across block boundaries" do
    test "stateful siblings survive a conditional toggle", %{page: page} do
      inputs = ["input_a", "input_b", "input_c"]

      # Each input is tagged with a property the diff never reads, so it lives exactly as long as
      # the DOM node does. The keeper wrapper is tagged too, which is what makes it possible to see
      # a keeper repurposed into a banner rather than merely replaced.
      mark_nodes = """
      #{inspect(inputs)}.forEach((id) => {
        const input = document.getElementById(id);
        input.__probe = id;
        input.closest(".keeper").__probe = id;
      });
      document.getElementById("input_a").focus();
      """

      # Clicked from a script rather than by the driver so the button never takes focus: any focus
      # loss below is then caused by the patch, which is the thing under test.
      toggle = ~s|document.querySelector("button").click();|

      kept_nodes = """
      return #{inspect(inputs)}.filter((id) => document.getElementById(id).__probe === id);
      """

      repurposed_keepers = """
      return ["panel_a", "panel_b", "panel_c"].filter(
        (id) => document.querySelector(`#${id} .banner`).__probe !== undefined,
      );
      """

      page =
        page
        |> visit(Page11)
        |> assert_text("#result", "false")
        |> fill_in("#input_a", with: "typed a")
        |> fill_in("#input_b", with: "typed b")
        |> fill_in("#input_c", with: "typed c")

      script_result(page, mark_nodes)
      script_result(page, toggle)

      page
      |> assert_text("#result", "true")
      |> assert_count(".banner", 3)
      |> assert_input_value("#input_a", "typed a")
      |> assert_input_value("#input_b", "typed b")
      |> assert_input_value("#input_c", "typed c")
      |> assert_script_result(kept_nodes, inputs)
      |> assert_script_result(repurposed_keepers, [])
      |> assert_focused("#input_a")
    end

    test "stateful siblings survive a branch switch", %{page: page} do
      inputs = ["input_a", "input_b"]

      mark_nodes = """
      #{inspect(inputs)}.forEach((id) => {
        const input = document.getElementById(id);
        input.__probe = id;
        input.closest(".keeper").__probe = id;
      });
      document.getElementById("input_a").focus();
      """

      switch = ~s|document.querySelector("button").click();|

      kept_nodes = """
      return #{inspect(inputs)}.filter((id) => document.getElementById(id).__probe === id);
      """

      repurposed_keepers = """
      return ["panel_a", "panel_b"].filter((id) =>
        [...document.querySelectorAll(`#${id} .branch`)].some((el) => el.__probe !== undefined),
      );
      """

      page =
        page
        |> visit(Page12)
        |> assert_text("#result", "true")
        |> fill_in("#input_a", with: "typed a")
        |> fill_in("#input_b", with: "typed b")

      script_result(page, mark_nodes)
      script_result(page, switch)

      page
      |> assert_text("#result", "false")
      |> assert_input_value("#input_a", "typed a")
      |> assert_input_value("#input_b", "typed b")
      |> assert_script_result(kept_nodes, inputs)
      |> assert_script_result(repurposed_keepers, [])
      |> assert_focused("#input_a")

      script_result(page, switch)

      page
      |> assert_text("#result", "true")
      |> assert_input_value("#input_a", "typed a")
      |> assert_input_value("#input_b", "typed b")
      |> assert_script_result(kept_nodes, inputs)
      |> assert_script_result(repurposed_keepers, [])
      |> assert_focused("#input_a")
    end

    test "stateful siblings survive loop changes", %{page: page} do
      inputs = ["input_a", "input_b"]

      mark_nodes = """
      #{inspect(inputs)}.forEach((id) => {
        document.getElementById(id).__probe = id;
      });
      """

      kept_nodes = """
      return #{inspect(inputs)}.filter((id) => document.getElementById(id).__probe === id);
      """

      page =
        page
        |> visit(Page13)
        |> click_button("Add item")
        |> click_button("Add item")
        |> assert_text("#result", "item 1, item 2, item 3")
        |> fill_in("#input_a", with: "typed a")
        |> fill_in("#input_b", with: "typed b")

      script_result(page, mark_nodes)

      # Switching the conditional inside the loop body renders the same key once per item, so this
      # is the patch that throws when repeated keys reach the diff unnumbered. It takes three of
      # them: with two the diff realigns on its own and the failure does not surface.
      page
      |> click_button("Toggle badges")
      |> assert_count(".badge", 0)
      |> assert_input_value("#input_a", "typed a")
      |> assert_input_value("#input_b", "typed b")
      |> assert_script_result(kept_nodes, inputs)
      |> click_button("Toggle badges")
      |> assert_count(".badge", 3)
      |> assert_input_value("#input_a", "typed a")
      |> assert_input_value("#input_b", "typed b")
      |> assert_script_result(kept_nodes, inputs)

      page
      |> click_button("Add item")
      |> assert_text("#result", "item 1, item 2, item 3, item 4")
      |> assert_input_value("#input_a", "typed a")
      |> assert_input_value("#input_b", "typed b")
      |> assert_script_result(kept_nodes, inputs)
      |> click_button("Remove item")
      |> click_button("Remove item")
      |> assert_text("#result", "item 1, item 2")
      |> assert_input_value("#input_a", "typed a")
      |> assert_input_value("#input_b", "typed b")
      |> assert_script_result(kept_nodes, inputs)
    end

    test "stateful siblings survive several conditionals switching at once", %{
      page: page
    } do
      fields = ["field_1", "field_2", "field_3"]

      mark_nodes = """
      #{inspect(fields)}.forEach((id) => {
        document.getElementById(id).__probe = id;
      });
      """

      kept_nodes = """
      return #{inspect(fields)}.filter((id) => document.getElementById(id).__probe === id);
      """

      typed_values = """
      return #{inspect(fields)}.map((id) => document.getElementById(id).value);
      """

      page =
        page
        |> visit(Page14)
        |> assert_text("#result", "true")
        |> assert_count(".hint", 3)
        |> fill_in("#field_1", with: "typed 1")
        |> fill_in("#field_2", with: "typed 2")
        |> fill_in("#field_3", with: "typed 3")

      script_result(page, mark_nodes)

      # Hiding is the direction that fails: three regions shrink in one patch, and the fields
      # between them are keyless. Values are read as a list so a value landing in a neighbouring
      # field is caught, not just a value going missing.
      page
      |> click_button("Toggle hints")
      |> assert_text("#result", "false")
      |> assert_count(".hint", 0)
      |> assert_script_result(typed_values, ["typed 1", "typed 2", "typed 3"])
      |> assert_script_result(kept_nodes, fields)
      |> click_button("Toggle hints")
      |> assert_text("#result", "true")
      |> assert_count(".hint", 3)
      |> assert_script_result(typed_values, ["typed 1", "typed 2", "typed 3"])
      |> assert_script_result(kept_nodes, fields)
    end

    test "reordering a list whose body holds a block", %{page: page} do
      # Read as one line of text so an entry rendered twice, or one that lost its star, shows up
      # here - the failure leaves the list half-updated rather than empty.
      rendered_feed = """
      return document.getElementById("feed").innerText.replace(/\\s+/g, " ").trim();
      """

      page
      |> visit(Page15)
      |> assert_text("#result", "Alpha, Bravo, Charlie, Delta")
      |> assert_script_result(rendered_feed, "* Alpha * Bravo * Charlie * Delta")
      |> click_button("Sort")
      |> assert_text("#result", "Charlie, Alpha, Delta, Bravo")
      |> assert_script_result(rendered_feed, "* Charlie * Alpha * Delta * Bravo")
      |> click_button("Sort")
      |> assert_text("#result", "Delta, Charlie, Bravo, Alpha")
      |> assert_script_result(rendered_feed, "* Delta * Charlie * Bravo * Alpha")
    end

    test "the key an element is diffed by never reaches the markup", %{page: page} do
      # The key is written as an attribute because that is how a value reaches an element through
      # every path a template has, but it is never one: the server leaves it out of the markup and
      # the client turns it into the vnode's key. Checked on both renderers' output, since either
      # could leak it on its own.
      framework_attributes = """
      return [...document.querySelectorAll("*")]
        .flatMap((element) => [...element.attributes])
        .map((attribute) => attribute.name)
        .filter((name) => name.startsWith("$"));
      """

      page
      |> visit(Page15)
      |> assert_script_result(framework_attributes, [])
      |> click_button("Sort")
      |> assert_text("#result", "Charlie, Alpha, Delta, Bravo")
      |> assert_script_result(framework_attributes, [])
    end

    test "no node of the framework's own is left in the page", %{page: page} do
      # Blocks used to be bracketed in comment markers so that a block changing how many nodes it
      # renders could not shift the identity of its siblings. Keys do that job now, and the page
      # holds only the nodes the template asks for.
      #
      # Every comment in the document is collected rather than only the ones near the block, since
      # a marker anywhere would be one too many, and the list is asserted whole: the author's own
      # comment has to be there, which is what shows the walk would have found a marker too.
      comments = """
      const walker = document.createTreeWalker(
        document.documentElement,
        NodeFilter.SHOW_COMMENT,
      );

      const found = [];

      while (walker.nextNode()) {
        found.push(walker.currentNode.textContent.trim());
      }

      return found;
      """

      authored = ["a comment the template author wrote"]

      page
      |> visit(Page15)
      |> assert_script_result(comments, authored)
      |> click_button("Sort")
      |> assert_text("#result", "Charlie, Alpha, Delta, Bravo")
      |> assert_script_result(comments, authored)
      |> click_button("Sort")
      |> assert_text("#result", "Delta, Charlie, Bravo, Alpha")
      |> assert_script_result(comments, authored)
    end
  end

  describe "keyed lists" do
    test "rows keep their nodes, typed values and focus when the first row is removed", %{
      page: page
    } do
      page
      |> visit(Page20)
      |> assert_text("#result", "Alpha, Bravo, Charlie")
      |> fill_in("#input_1", with: "typed 1")
      |> fill_in("#input_2", with: "typed 2")
      |> fill_in("#input_3", with: "typed 3")
      |> mark_nodes(@page20_rows)
      |> focus_by_script("input_2")
      |> click_by_script("remove_first")
      |> assert_text("#result", ~r/^Bravo, Charlie$/)
      |> assert_script_result(row_ids_script("rows"), ["row_2", "row_3"])
      |> assert_input_value("#input_2", "typed 2")
      |> assert_input_value("#input_3", "typed 3")
      |> assert_script_result(kept_nodes_script(["row_2", "row_3"]), ["row_2", "row_3"])
      |> assert_focused("#input_2")
    end

    test "rows keep their nodes and typed values when the list is reversed", %{
      page: page
    } do
      page
      |> visit(Page20)
      |> assert_text("#result", "Alpha, Bravo, Charlie")
      |> fill_in("#input_1", with: "typed 1")
      |> fill_in("#input_3", with: "typed 3")
      |> mark_nodes(@page20_rows)
      |> click("#reverse")
      |> assert_text("#result", ~r/^Charlie, Bravo, Alpha$/)
      |> assert_script_result(row_ids_script("rows"), ["row_3", "row_2", "row_1"])
      |> assert_input_value("#input_1", "typed 1")
      |> assert_input_value("#input_3", "typed 3")
      |> assert_script_result(kept_nodes_script(@page20_rows), @page20_rows)
    end

    test "rows keep their nodes, typed values and focus when a row is inserted in the middle",
         %{page: page} do
      page
      |> visit(Page20)
      |> assert_text("#result", "Alpha, Bravo, Charlie")
      |> fill_in("#input_2", with: "typed 2")
      |> mark_nodes(@page20_rows)
      |> focus_by_script("input_2")
      |> click_by_script("insert_in_middle")
      |> assert_text("#result", ~r/^Alpha, Delta, Bravo, Charlie$/)
      |> assert_script_result(row_ids_script("rows"), ["row_1", "row_4", "row_2", "row_3"])
      |> assert_input_value("#input_2", "typed 2")
      |> assert_input_value("#input_4", "")
      |> assert_script_result(kept_nodes_script(@page20_rows), @page20_rows)
      |> assert_focused("#input_2")
    end

    test "a spent once binding stays with its item when the item before it is removed", %{
      page: page
    } do
      # Matched by position, Bravo's row would take over the spent node and its claim would never
      # dispatch.
      page
      |> visit(Page20)
      |> click("#claim_1")
      |> assert_text("#claims", ~r/^Alpha$/)
      |> click("#remove_first")
      |> assert_text("#result", ~r/^Bravo, Charlie$/)
      |> click("#claim_2")
      |> assert_text("#claims", ~r/^Alpha, Bravo$/)
    end

    test "a spent once binding stays with its item across a reorder", %{page: page} do
      # Alpha's binding is spent wherever its row went, and Charlie's row, now first, is still
      # armed. Matched by position instead, Charlie would inherit the spent node and Alpha a fresh
      # one.
      page
      |> visit(Page20)
      |> mark_nodes(@page20_rows)
      |> click("#claim_1")
      |> assert_text("#claims", ~r/^Alpha$/)
      |> click("#reverse")
      |> assert_text("#result", ~r/^Charlie, Bravo, Alpha$/)
      |> assert_script_result(kept_nodes_script(@page20_rows), @page20_rows)
      |> click("#claim_1")
      |> click("#claim_3")
      |> assert_text("#claims", ~r/^Alpha, Charlie$/)
    end

    test "a navigation to the page keeps the rows its first patch put on screen", %{
      page: page
    } do
      # The navigation's first patch builds the rows from the tree the server sent, and the render
      # that follows keys them itself: keys that disagree with the server's rebuild every row,
      # which runs its script again. The flag set before the click survives only a navigation the
      # client made, so it proves the rows came from the tree rather than from a page load.
      page = visit(page, Page21)

      script_result(page, "window.__fromPage21 = true;")

      page
      |> click_link("Keyed list link")
      |> assert_page(Page20)
      |> assert_script_result("return window.__fromPage21 === true;", true)
      |> assert_script_result("return window.__rowRuns;", 3)
      |> click("#reverse")
      |> assert_text("#result", ~r/^Charlie, Bravo, Alpha$/)
      |> assert_script_result("return window.__rowRuns;", 3)
      |> assert_script_result(stamped_rows_script(@page20_rows), @page20_rows)
    end

    test "the first render keeps the rows the server sent", %{page: page} do
      # On a page load the first patch takes its keys from the client's own render, so this guards
      # that loop items are adopted at boot, not that the server's keys agree - the navigation
      # feature above guards that.
      page
      |> visit(Page20)
      |> click("#reverse")
      |> assert_text("#result", ~r/^Charlie, Bravo, Alpha$/)
      |> assert_script_result("return window.__rowRuns;", 3)
      |> assert_script_result(stamped_rows_script(@page20_rows), @page20_rows)
    end
  end

  describe "explicitly keyed lists" do
    test "rows keyed by a $key on their element keep their nodes and typed values", %{
      page: page
    } do
      assert_rows_follow_their_items(page, Page22, "element")
    end

    test "rows keyed by a $key on a stateless component keep their nodes and typed values", %{
      page: page
    } do
      assert_rows_follow_their_items(page, Page22, "component")
    end

    test "stateful component rows keyed by their cid keep their nodes and typed values", %{
      page: page
    } do
      assert_rows_follow_their_items(page, Page22, "stateful")
    end

    test "rows keyed by an identifier $key keep their nodes and typed values", %{
      page: page
    } do
      assert_rows_follow_their_items(page, Page23, "identifier")
    end

    test "rows keyed by a record $key keep their nodes and typed values", %{
      page: page
    } do
      assert_rows_follow_their_items(page, Page23, "record")
    end

    test "a navigation to the page keeps the rows its first patch put on screen", %{
      page: page
    } do
      # The navigation's first patch builds the rows from the tree the server sent, and the render
      # that follows keys them itself: a list whose keys disagree with the server's rebuilds its
      # rows, which runs their scripts again. The flag set before the click survives only a
      # navigation the client made, so it proves the rows came from the tree rather than from a
      # page load.
      rows =
        for kind <- ["element", "component", "stateful"],
            name <- ["alpha", "bravo", "charlie"],
            do: "#{kind}_row_#{name}"

      page = visit(page, Page21)

      script_result(page, "window.__fromPage21 = true;")

      page
      |> click_link("Explicitly keyed lists link")
      |> assert_page(Page22)
      |> assert_script_result("return window.__fromPage21 === true;", true)
      |> assert_script_result("return window.__rowRuns;", 9)
      |> click("#reverse")
      |> assert_text("#result", ~r/^charlie, bravo, alpha$/)
      |> assert_script_result("return window.__rowRuns;", 9)
      |> assert_script_result(stamped_rows_script(rows), rows)
    end
  end

  describe "adopting the server-rendered page" do
    test "the first render keeps the nodes the server sent", %{page: page} do
      server_nodes = """
      return ["kept", "hint", "field", "marked", "result", "photo"].filter(
        (id) => document.getElementById(id).__fromServer === true,
      );
      """

      ids = ["kept", "hint", "field", "marked", "result", "photo"]

      head_nodes = """
      return Array.from(document.head.children).map((node) => [
        node.tagName.toLowerCase(),
        node.__fromServer === true,
      ]);
      """

      # Everything the render still names is the node the server sent, and the runtime's scripts,
      # which it no longer names, are gone rather than rebuilt.
      adopted_head = [["meta", true], ["meta", true], ["script", true], ["style", true]]

      page =
        page
        |> visit(Page16)
        |> assert_text("#result", "0")
        |> fill_in("#field", with: "typed")

      # Waiting for a click to land proves the client has rendered: the assertions below would
      # pass on their own against a page that had booted no further than the server's markup.
      page
      |> click_button("Increment")
      |> assert_text("#result", "1")
      # A script element runs when it is created, so a second run means the first patch rebuilt
      # the page rather than adopting it - and it would fire a real page's analytics twice.
      |> assert_script_result("return window.__scriptRuns;", 1)
      |> assert_script_result(server_nodes, ids)
      |> assert_script_result(head_nodes, adopted_head)
      |> assert_input_value("#field", "typed")
      |> click_button("Increment")
      |> assert_text("#result", "2")
      |> assert_script_result("return window.__scriptRuns;", 1)
      |> assert_script_result(server_nodes, ids)
      |> assert_script_result(head_nodes, adopted_head)
      |> assert_input_value("#field", "typed")
      # An image the patch rebuilt loads a second time, from the cache if not from the network, so
      # a single load is what says the server's own is the one still on the page. Counted at the
      # end, where every render so far has had its chance to add to it.
      |> assert_script_result("return window.__imageLoads;", 1)
    end

    test "the first render keeps the state those nodes hold", %{page: page} do
      # Incremented from a script rather than by the driver so the button never takes focus: the
      # focus below is then the one the page set before booting, which is the thing under test.
      increment = ~s|document.querySelector("button").click();|

      state = """
      const field = document.getElementById("field");

      return [
        document.activeElement.id,
        field.selectionStart,
        field.selectionEnd,
        document.getElementById("feed").scrollTop,
      ];
      """

      page = visit(page, Page16)

      script_result(page, increment)

      page
      |> assert_text("#result", "1")
      |> assert_script_result(state, ["field", 2, 5, 30])
    end
  end

  describe "adopting an element whose tag name carries case" do
    test "the first render keeps the SVG element the server sent", %{page: page} do
      server_nodes = """
      return ["art", "grad"].filter(
        (id) => document.getElementById(id).__fromServer === true,
      );
      """

      ids = ["art", "grad"]

      page
      |> visit(Page18)
      |> assert_text("#result", "0")
      # Waiting for a click to land proves the client has rendered: the assertions below would
      # pass on their own against a page that had booted no further than the server's markup.
      |> click_button("Increment")
      |> assert_text("#result", "1")
      # A script element runs when it is created, so a second run means the first render rebuilt
      # the page rather than adopting it, and the stamps below would be its own work.
      |> assert_script_result("return window.__scriptRuns;", 1)
      |> assert_script_result(server_nodes, ids)
    end
  end

  describe "building an element the server never sent" do
    test "an SVG tag name is built under the name the parser gives it", %{page: page} do
      name = ~s|return document.getElementById("grad").localName;|

      page
      |> visit(Page19)
      |> assert_text("#result", "false")
      |> click_button("Show")
      |> assert_text("#result", "true")
      |> assert_script_result(name, "linearGradient")
    end
  end

  describe "element state across a patch" do
    test "a scrolled container holds its place when a sibling appears", %{
      page: page
    } do
      scroll = ~s|document.getElementById("feed").scrollTop = 30;|

      # Toggled from a script rather than by the driver, the way the sibling identity tests do it,
      # so nothing the driver does can be mistaken for what the patch did.
      toggle = ~s|document.querySelector("button").click();|

      scroll_top = ~s|return document.getElementById("feed").scrollTop;|

      page = visit(page, Page17)

      script_result(page, scroll)

      page
      |> assert_text("#result", "false")
      |> assert_script_result(scroll_top, 30)

      script_result(page, toggle)

      page
      |> assert_text("#result", "true")
      |> assert_count(".banner", 3)
      |> assert_script_result(scroll_top, 30)
    end

    test "a selection survives a sibling appearing", %{page: page} do
      select = """
      const field = document.getElementById("field");

      field.value = "server text";
      field.setSelectionRange(2, 5);
      """

      toggle = ~s|document.querySelector("button").click();|

      # The field is left unfocused on purpose: focus across a patch is already covered by the
      # sibling identity tests, so what is measured here is the range alone.
      selection = """
      const field = document.getElementById("field");

      return [field.value, field.selectionStart, field.selectionEnd];
      """

      page = visit(page, Page17)

      script_result(page, select)

      page
      |> assert_text("#result", "false")
      |> assert_script_result(selection, ["server text", 2, 5])

      script_result(page, toggle)

      page
      |> assert_text("#result", "true")
      |> assert_count(".banner", 3)
      |> assert_script_result(selection, ["server text", 2, 5])
    end

    test "an image is not loaded again when a sibling appears", %{page: page} do
      mark = ~s|document.getElementById("photo").__probe = "photo";|

      toggle = ~s|document.querySelector("button").click();|

      # The marker says whether it is still the same node, the counter what that cost if it is not.
      # Both are asked, because identity is the mechanism and the load is the consequence the issue
      # was reported for.
      photo = """
      return [
        document.getElementById("photo").__probe ?? null,
        window.__imageLoads,
      ];
      """

      page = visit(page, Page17)

      script_result(page, mark)

      page
      |> assert_text("#result", "false")
      |> assert_script_result(photo, ["photo", 1])

      script_result(page, toggle)

      page
      |> assert_text("#result", "true")
      |> assert_count(".banner", 3)
      |> assert_script_result(photo, ["photo", 1])
    end
  end

  describe "form element values the browser reformats" do
    test "a re-render leaves a color the browser lowercased alone", %{page: page} do
      page
      |> visit(Page24)
      |> click_button("Rerender")
      |> click_button("Rerender")
      |> assert_text("#result", "2")
      # The one write is the first render's: the attribute the server sent is removed when the
      # client takes the page over, and the value from state is written in its place.
      |> assert_script_result("return window.__valueWrites.color_input;", 1)
    end

    test "a re-render leaves a range value the browser snapped to its step alone", %{
      page: page
    } do
      writes = "return window.__valueWrites.range_input;"

      page
      |> visit(Page24)
      # The first render's write, as for the color input above.
      |> assert_script_result(writes, 1)
      |> click_button("Rerender")
      |> click_button("Rerender")
      |> click_button("Rerender")
      |> assert_text("#result", "3")
      |> assert_script_result(~s|return document.getElementById("range_input").value;|, "50")
      |> assert_script_result(writes, 1)
    end

    test "a picked color the action upcases is not written back", %{page: page} do
      pick = """
      const input = document.getElementById("color_input");

      window.__nativeValue.set.call(input, "#ff8800");
      input.dispatchEvent(new Event("input", {bubbles: true}));
      """

      page =
        page
        |> visit(Page24)
        |> assert_script_result("return window.__valueWrites.color_input;", 1)

      script_result(page, pick)

      page
      |> assert_text("#state", "#FF8800")
      |> assert_script_result("return window.__valueWrites.color_input;", 1)
    end
  end
end
