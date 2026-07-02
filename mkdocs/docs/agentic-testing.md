---
title: Agentic Workflow Testing
---

# Agentic Workflow Testing

Agent frameworks wrap an LLM in a tool-calling loop:

```
model → tool_call → tool executes → tool_result → model → … → final answer
```

The loop terminates when the model stops requesting tools and produces a
plain-text answer. **Naïve mocks can't replicate this.** They either always
return a tool call (the agent loops forever) or never return one (tool tests
can't fire). VidaiMock does both correctly — it behaves like a real model
that knows when it's done.

This is the single biggest reason to use VidaiMock for agent development:
**run Google ADK, LangGraph, or LangChain Runner loops end-to-end in CI
with zero live-provider spend** — the loop terminates naturally, just like
it does against the real API.

## The two branches

The bundled chat templates decide based on the request history:

- **Tools defined, no tool result yet** → emit a `tool_call` / `tool_use` /
  `functionCall`.
- **Tools defined, tool result already in history** → emit a plain-text
  answer with `finish_reason: "stop"` / `stop_reason: "end_turn"`.

## How it detects a tool result

A built-in Tera helper, `has_tool_result(messages, provider)`, inspects the
request's conversation history. It's implemented in Rust (not Tera) because
deep JSON-array inspection is unreliable in templates.

| `provider` | Detection signal |
|---|---|
| `openai` | any message with `role: "tool"` |
| `anthropic` | a user message whose `content[]` contains a block with `type: "tool_result"` |
| `gemini` | user content whose `parts[]` contains a `functionResponse` |

Default is `openai` when `provider` is omitted. Malformed or missing input
returns `false` rather than erroring — safe to use unconditionally inside
`{% if %}` guards in custom templates.

## The full round trip (OpenAI, no API key, no cost)

**Turn 1** — the agent asks; the mock returns a tool call because `tools`
are declared and there's no tool result yet:

```bash
curl -s http://localhost:8100/v1/chat/completions -H 'Content-Type: application/json' \
  -d '{"model":"gpt-4o",
       "tools":[{"type":"function","function":{"name":"get_weather","parameters":{}}}],
       "messages":[{"role":"user","content":"Weather in London?"}]}'
# -> finish_reason: "tool_calls", message.tool_calls: [...]
```

Your agent framework executes `get_weather`, appends the result, and calls
again.

**Turn 2** — same tools, now with a `role:tool` result in history. The mock
detects it and synthesises a plain-text answer instead of looping:

```bash
curl -s http://localhost:8100/v1/chat/completions -H 'Content-Type: application/json' \
  -d '{"model":"gpt-4o",
       "tools":[{"type":"function","function":{"name":"get_weather","parameters":{}}}],
       "messages":[
         {"role":"user","content":"Weather in London?"},
         {"role":"assistant","tool_calls":[{"id":"c1","type":"function",
            "function":{"name":"get_weather","arguments":"{}"}}]},
         {"role":"tool","tool_call_id":"c1","content":"15°C cloudy"}
       ]}'
# -> finish_reason: "stop", message.content: "Based on the tool results..."
```

The agent loop terminates. No infinite recursion, no real tokens spent.

## Works in streaming too

The same heuristic applies to streaming requests. An Anthropic stream with a
`tool_result` already in history emits proper text deltas with
`stop_reason: end_turn` — agentic loops over streaming also terminate
cleanly in mock mode.

## Use in custom templates

If you write your own provider template, call the helper directly:

```jinja2
{% if json.tools and has_tool_result(messages=json.messages, provider="openai") %}
  {# loop-terminating: emit plain text #}
{% elif json.tools %}
  {# emit a tool call #}
{% else %}
  {# default text #}
{% endif %}
```

See [Writing templates](configuration/templates.md) for the full helper
catalogue.
