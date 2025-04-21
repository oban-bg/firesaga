# FireSaga

Fire Saga is a workflow that generates a collection of children's stories based on a topic using
generative AI. The authors are selected at random, then a short children's story and an
illustration are generated for each author before it's all packaged together with cover art in a
tidy markdown file.

## Usage

_🌟 You'll need an active Oban Pro license and OpenAI keys to run the demo_

Clone the repository, then install the dependencies:

```bash
mix deps.get
```

Create the database and run the migrations:

```bash
mix run ecto.create,ecto.migrate
```

Run the tests to make sure everything installed:

```bash
mix test
```

Now you can generate a story. Start an `iex` session, then start a workflow:

```iex
FireSaga.Story.insert(chapters: 3, topic: "whatever silly topic you want")
```

Wait a moment and it will spit out the markdown for a collection of stories with images.
