defmodule FireSaga.LLM do
  def chat!(prompt) do
    body = %{model: "gpt-4o-mini", messages: [%{role: "user", content: prompt}]}
    case post(:ttt, json: body) do
      {:ok, %{body: body}} -> get_in(body, ["choices", Access.at(0), "message", "content"])
      error -> raise error
    end
  end

  def image!(prompt) do
    body = %{model: "dall-e-3", prompt: prompt, size: "1024x1024"}
    case post(:tti, json: body) do
      {:ok, %{body: body, status: 200}} -> get_in(body, ["data", Access.at(0), "url"])
      error -> raise error
    end
  end

  defp post(:ttt, opts) do
    api_key = Application.fetch_env!(:fire_saga, :openai_ttt_api)
    url = Application.fetch_env!(:fire_saga, :openai_ttt)
    post_request(opts, api_key, url)
  end

  defp post(:tti, opts) do
    api_key = Application.fetch_env!(:fire_saga, :openai_tti_api)
    url = Application.fetch_env!(:fire_saga, :openai_tti)
    post_request(opts, api_key, url)
  end

  defp post_request(opts, api_key, url) do
    oorg_id = Application.fetch_env!(:fire_saga, :openai_org_id)
    defaults = [
      url: url,
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
