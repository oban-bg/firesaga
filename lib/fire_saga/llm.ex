defmodule FireSaga.LLM do
  def chat!(prompt) do
    body = %{model: "gpt-4o-mini", messages: [%{role: "user", content: prompt}]}

    case post(json: body, url: "https://api.openai.com/v1/chat/completions") do
      {:ok, %{body: body}} -> get_in(body, ["choices", Access.at(0), "message", "content"])
      error -> raise error
    end
  end

  def image!(prompt) do
    body = %{model: "dall-e-3", prompt: prompt}

    case post(json: body, url: "https://api.openai.com/v1/images/generations") do
      {:ok, %{body: body, status: 200}} -> get_in(body, ["data", Access.at(0), "url"])
      error -> raise error
    end
  end

  defp post(opts) do
    api_key = Application.fetch_env!(:fire_saga, :openai_api_key)
    oorg_id = Application.fetch_env!(:fire_saga, :openai_org_id)

    defaults = [
      auth: {:bearer, api_key},
      headers: %{"openai-organization" => oorg_id},
      receive_timeout: 60_000
    ]

    app_opts = Application.get_env(:fire_saga, __MODULE__, [])

    opts
    |> Keyword.merge(defaults)
    |> Keyword.merge(app_opts)
    |> Req.post()
  end
end
