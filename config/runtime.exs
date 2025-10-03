import Config

config :fire_saga,
  openai_ttt: System.get_env("OPENAI_TTT_URL") || "https://api.openai.com/v1/chat/completions",
  openai_tti: System.get_env("OPENAI_TTI_URL") || "https://api.openai.com/v1/images/generations",
  openai_ttt_api: System.get_env("OPENAI_TTT_API"),
  openai_tti_api: System.get_env("OPENAI_TTI_API"),
  openai_org_id: System.get_env("OPENAI_ORG_ID")
