import Config

config :fire_saga,
  openai_ttt: System.get_env("OPENAI_TTT_URL") || "https://api.openai.com/v1/chat/completions",
  openai_tti: System.get_env("OPENAI_TTI_URL") || "https://api.openai.com/v1/images/generations",
  openai_api_key: System.get_env("OPENAI_API_KEY"),
  openai_org_id: System.get_env("OPENAI_ORG_ID")
