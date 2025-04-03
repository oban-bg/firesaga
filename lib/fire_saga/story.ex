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
    |> Workflow.add_many(:story, Enum.map((0..count - 1), &new_gen_story/1), deps: :authors)
    |> Workflow.add_many(:image, Enum.map((0..count - 1), &new_gen_image/1), deps: :story)
    |> Workflow.add(:title, new_gen_title(), deps: :story)
    |> Workflow.add(:cover, new_gen_cover(), deps: :story)
    |> Workflow.add(:print, new_print(), deps: [:title, :cover])
  end

  @job recorded: true
  def gen_authors(count) do
    prompt = """
    Generate a bulleted list of thirty prominent children's authors.
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
    Generate a short, one-two paragraph story about #{topic} in the style of #{author}. Include a
    title for the story and format the output using the following template:

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
    story = recorded |> Map.get("story") |> Map.get(to_string(index))

    prompt = """
    Generate an original illustration for a children's story by #{author}, in their style. The
    illustration is about the following story: story: #{story}
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

  @job true
  def print do
    recorded = Workflow.all_recorded(current_job(), with_subs: true)

    maybe_download_image(recorded["cover"], "cover.jpg")

    story_pages =
      recorded["authors"]
      |> Enum.with_index()
      |> Enum.map(fn {author, index} ->
        recorded["image"]
        |> Map.get(to_string(index))
        |> maybe_download_image("image_#{index}.jpg")

        story = Map.get(recorded["story"], to_string(index))

        """
        #### By: #{author}

        ![](image_#{index}.jpg)

        #{story}

        ---

        """
      end)

    title_page = """
    # #{recorded["title"]}

    ![Cover](cover.jpg)

    ---

    """

    [title_page, story_pages]
    |> IO.iodata_to_binary()
    |> IO.puts()
  end

  defp maybe_download_image(url, path) do
    if url =~ "https" do
      Req.get!(url, into: File.stream!(path))
    end
  end
end
