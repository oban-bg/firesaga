defmodule FireSagaTest do
  use ExUnit.Case, async: true

  use Oban.Pro.Testing, repo: FireSaga.Repo

  alias Ecto.Adapters.SQL.Sandbox
  alias FireSaga.{LLM, Repo, Story}

  setup do
    pid = Sandbox.start_owner!(Repo, shared: false)

    on_exit(fn -> Sandbox.stop_owner(pid) end)
  end

  test "generating a complete story" do
    id = Oban.Pro.UUIDv7.generate()

    expect_chat("- Beverly Cleary\n- Jean Craighead George\n- Alexander Key", 1)
    expect_chat("A little story, here it goes", 3)
    expect_image("image.jpg", 3)
    expect_chat("Collection of Stories", 1)
    expect_image("cover.jpg", 1)

    assert %{completed: 11} =
             [topic: "Story about things", chapters: 3]
             |> Story.build()
             |> run_workflow(workflow_id: id)
  end

  defp expect_chat(content, count) do
    body = %{"choices" => [%{"message" => %{"content" => content}}]}

    Req.Test.expect(LLM, count, &Req.Test.json(&1, body))
  end

  defp expect_image(content, count) do
    body = %{"data" => [%{"url" => content}]}

    Req.Test.expect(LLM, count, &Req.Test.json(&1, body))
  end
end
