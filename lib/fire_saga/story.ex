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

    Workflow.new()
    |> Workflow.put_context(%{topic: topic})
    |> Workflow.add(:authors, new_gen_authors(count))
    |> Workflow.add_many(:stories, Enum.map((0..count - 1), &new_gen_story/1), deps: :authors)
    |> Workflow.add_many(:images, Enum.map((0..count - 1), &new_gen_image/1), deps: :stories)
    |> Workflow.add(:title, new_gen_title(), deps: :stories)
    |> Workflow.add(:cover, new_gen_cover(), deps: :stories)
    |> Workflow.add(:print, new_print(), deps: [:title, :cover])
  end

  @job recorded: true
  def gen_authors(count) do
    prompt = """
    Generate an unordered list of thirty prominent children's authors. Use a leading hyphen rather
    than numbers for each list item.

    Do not include the following authors:

    - J.K. Rowling
    - C.S. Lewis
    - J.R.R. Tolkien
    """

    authors =
      prompt
      |> LLM.chat!()
      |> String.split("\n", trim: true)
      |> Enum.map(&String.trim_leading(&1, "- "))
      |> Enum.take_random(count)

    {:ok, authors}
  end

  @job recorded: true
  def gen_story(index) do
    workflow_id = current_job().meta["sup_workflow_id"]

    %{topic: topic} = Workflow.get_context(workflow_id)

    author =
      workflow_id
      |> Workflow.get_recorded(:authors)
      |> Enum.at(index + 1)

    prompt = """
    You are #{author}. Write a one paragraph story about "#{topic}". Include a title for the story
    and format the output using the following template:

    ## TITLE

    STORY
    """

    {:ok, LLM.chat!(prompt)}
  end

  @job recorded: true
  def gen_image(index) do
    job = current_job()

    recorded = Workflow.all_recorded(job.meta["sup_workflow_id"], with_subs: true)
    author = recorded |> Map.get("authors") |> Enum.at(index + 1)
    story = recorded |> Map.get("stories") |> Map.get(to_string(index))

    prompt = """
    You are #{author}. Create an illustration for the children's story: #{story}
    """

    {:ok, LLM.image!(prompt)}
  end

  @job recorded: true
  def gen_title do
    %{topic: topic} = Workflow.get_context(current_job())

    prompt = """
    Create a title for a collection of children's stories about #{topic}. The title should be
    brief, playful, and possibly funny.
    """

    {:ok, LLM.chat!(prompt)}
  end

  @job recorded: true
  def gen_cover do
    %{topic: topic} = Workflow.get_context(current_job())

    prompt = """
    Illustrate an original cover for a collection of children's stories about #{topic}. Don't
    include any text.
    """

    {:ok, LLM.image!(prompt)}
  end

  @template """
  # <%= title %>

  ![Cover](cover.jpg)

  ---

  <%= for {index, story} <- stories do %>
    ![](image_<%= index %>.jpg)

    _Inspired By: <%= Enum.at(authors, String.to_integer(index)) %>_

    <%= story %>

    ---
  <% end %>
  """

  @job true
  def print do
    recorded =
      current_job()
      |> Workflow.all_recorded(with_subs: true)
      |> Keyword.new(fn {key, val} -> {String.to_existing_atom(key), val} end)

    recorded[:images]
    |> Enum.map(fn {idx, url} -> {url, "image_#{idx}.jpg"} end)
    |> Enum.concat([{recorded[:cover], "cover.jpg"}])
    |> Enum.each(&download_image/1)

    @template
    |> EEx.eval_string(recorded)
    |> then(&File.write!("story.md", &1))
  end

  defp download_image({url, path}) do
    if url =~ "https" do
      Req.get!(url, into: File.stream!(path))
    end
  end
end
