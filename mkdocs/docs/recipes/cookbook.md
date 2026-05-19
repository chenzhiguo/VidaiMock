---
title: Cookbook
---

# Cookbook

Ready-to-use recipes for common and edge-case scenarios. All examples are
plain Tera templates you drop into your `--config-dir`. The bundled
`examples/templates/` directory in the repo has 20+ more.

## Conditional logic

Return a different answer based on the user's message:

```jinja2
{
  "id": "chatcmpl-{{ uuid() }}",
  "choices": [{
    "message": {
      "role": "assistant",
      "content": "{% if json.messages | last | get(key='content') | lower is containing('error') %}I am simulating an error scenario for you.{% else %}Everything looks normal.{% endif %}"
    },
    "finish_reason": "stop"
  }]
}
```

## Maintenance / overloaded mode

Pair this template with `error_template` and a 503 `status_code` so it's
returned as a real failure (see
[Chaos & error injection](../chaos-and-errors.md)):

```jinja2
{
  "error": {
    "message": "The model is currently overloaded. Please try again later.",
    "type": "server_error",
    "code": "model_overloaded"
  }
}
```

## Fuzzing / large payloads

Stress your client's buffers and UI with bulk random data:

```jinja2
{
  "id": "fuzz-{{ uuid() }}",
  "choices": [{
    "message": {
      "role": "assistant",
      "content": "{% for i in range(end=100) %}FUZZ_{{ random_int(min=0, max=999999) }} {% endfor %}"
    },
    "finish_reason": "stop"
  }]
}
```

## Non-JSON content types

VidaiMock isn't only for JSON — set `--content-type` and serve anything.

**CSV** (RAG ingestion tests):

```jinja2
id,name,role,created_at
{{ uuid() }},Alice,Admin,{{ iso_timestamp() }}
{{ uuid() }},Bob,User,{{ iso_timestamp() }}
```

**SOAP/XML** (legacy enterprise mocks):

```jinja2
<?xml version="1.0"?>
<soap:Envelope>
  <soap:Body>
    <Response><Id>{{ uuid() }}</Id><Status>OK</Status></Response>
  </soap:Body>
</soap:Envelope>
```

## Agentic loop (zero-token CI)

The flagship recipe — drive an ADK / LangGraph / LangChain Runner loop
end-to-end with no live tokens. The bundled chat template already does
this; see [Agentic workflow testing](../agentic-testing.md) for the full
two-turn round trip.

## Forced upstream failure for fallback tests

Register a "broken" and a "healthy" upstream against the **same** instance:

```
primary  : http://vidaimock:8100/v1?chaos_status=500
fallback : http://vidaimock:8100/v1
```

The system under test can't tell it's the same mock. See
[Chaos & error injection](../chaos-and-errors.md).

## More

The repo's `examples/` directory ships 20+ advanced templates — RAG
citations, structured math solving, GraphQL, HTML pages, security fuzzing,
and more. They're bundled in every release archive.
