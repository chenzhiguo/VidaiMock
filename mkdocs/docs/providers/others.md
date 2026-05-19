---
title: Other Providers
---

# Other Providers

Beyond the big three, VidaiMock ships drop-in support for the other surfaces
real applications hit. All are bundled and require zero configuration.

## Azure OpenAI

```
POST /openai/deployments/{deployment}/chat/completions
POST /openai/deployments/{deployment}/embeddings
```

Azure uses the OpenAI request/response shape under a deployment-scoped path.
The bundled Azure provider matches the deployment path pattern and serves
the OpenAI templates, so any Azure OpenAI SDK works unchanged — just point
its endpoint at VidaiMock.

## AWS Bedrock

```
POST /model/{model_id}/invoke
POST /model/{model_id}/converse
POST /model/{model_id}/invoke-with-response-stream
POST /model/{model_id}/converse-stream
```

Bedrock's binary event-stream framing is emulated for the streaming variants.

## Vertex AI

```
POST /v1/projects/{project}/locations/{location}/publishers/google/models/{model}:generateContent
```

The Gemini response shape under Vertex's project/location-scoped path.

## OpenAI-compatible providers

Cohere, Mistral, and Groq all expose OpenAI-compatible chat endpoints.
Point any OpenAI SDK at VidaiMock with the relevant model name — the
OpenAI-compatible catch-all handles `/v1/chat/completions` for these
providers, including streaming.

## Anything else

Every endpoint above is just a bundled provider YAML + Tera template. To add
a provider VidaiMock does not ship, drop a YAML into your `--config-dir`
with a matching regex and a response template. See
[Provider config reference](../configuration/provider-config.md) and
[Overriding bundled defaults](../configuration/overriding.md).
