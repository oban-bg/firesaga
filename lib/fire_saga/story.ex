defmodule FireSaga.Story do
  use Oban.Pro.Decorator

  alias FireSaga.LLM
  alias Oban.Pro.Workflow

  def insert(opts) do
    opts
    |> build()
    |> Oban.insert_all()
  end

  def build(opts) when is_list(opts) do
    topic = Keyword.fetch!(opts, :topic)
    count = Keyword.fetch!(opts, :chapters)
    range = 0..(count - 1)

    Workflow.new()
    |> Workflow.put_context(%{count: count, topic: topic})
    |> Workflow.add_cascade(:authors, &gen_authors/1)
    |> Workflow.add_cascade(:stories, {range, &gen_story/2}, deps: :authors)
    |> Workflow.add_cascade(:images, {range, &gen_image/2}, deps: ~w(authors stories))
    |> Workflow.add_cascade(:title, &gen_title/1, deps: :stories)
    |> Workflow.add_cascade(:cover, &gen_cover/1, deps: :stories)
    |> Workflow.add_cascade(:print, &print/1, deps: ~w(authors cover images stories title))
  end

  def gen_authors(%{count: count}) do
    prompt = """
    Generate an unordered list of thirty prominent children's authors. Use a leading hyphen rather
    than numbers for each list item.

    Do not include the following authors:

    - J.K. Rowling
    - C.S. Lewis
    - J.R.R. Tolkien
    """

    prompt
    |> LLM.chat!()
    |> String.split("\n", trim: true)
    |> Enum.map(&String.trim_leading(&1, "- "))
    |> Enum.take_random(count)
  end

  def gen_story(index, %{authors: authors, topic: topic}) do
    author = Enum.at(authors, index)

    LLM.chat!("""
    You are #{author}. Write a one paragraph story about "#{topic}" including a title.
    """)
  end

  def gen_image(index, %{authors: authors, stories: stories}) do
    author = Enum.at(authors, index)
    story = Map.get(stories, to_string(index))

    LLM.image!("""
    You are #{author}. Create an illustration for the children's story: #{story}
    """)
  end

  def gen_title(%{topic: topic}) do
    LLM.chat!("""
    Create a title for a collection of children's stories about #{topic}. The title should be
    brief, playful, and possibly funny.
    """)
  end

  def gen_cover(%{topic: topic}) do
    LLM.image!("""
    Illustrate an original cover for a collection of children's stories about #{topic}. Don't
    include any text.
    """)
  end

  @template """
  # <%= title %>

  ![Cover](cover.png)

  ---

  <%= for {index, story} <- stories do %>
    ![](image_<%= index %>.png)

    _Inspired By: <%= Enum.at(authors, String.to_integer(index)) %>_

    <%= story %>

    ---
  <% end %>
  """

  def print(context) do
    context.images
    |> Enum.map(fn {idx, url} -> {url, "image_#{idx}.png"} end)
    |> Enum.concat([{context.cover, "cover.png"}])
    |> Enum.each(&download_image/1)

    @template
    |> EEx.eval_string(Keyword.new(context))
    |> then(&File.write!("story.md", &1))
  end

  defp download_image({url, path}) do
    if url =~ "https" do
      Req.get!(url, into: File.stream!(path))
    end
  end
end
