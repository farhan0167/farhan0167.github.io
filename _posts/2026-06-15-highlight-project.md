---
layout: post
title: Building an agent harness from scratch (Part 1)
date: 2026-06-15 09:00:00
description: What I learned wiring up tool-calling, memory, and a control loop into a tiny, hackable agent kit.
featured: true
thumbnail: assets/img/9.jpg
categories: projects
tags: agents llms
author: Ahmad Farhan Ishraq
pseudocode: true
toc:
  minimap: true
---

In October of 2025, I finally decided to give a shot at Claude Code, and how I coded has largely changed since. I'm sure we all have some version of the same story. What mostly impressed on me is how a seemingly simple, or as I had believed at the time, LLM call can have such an impact once you arm it with tool calling. Agent Harness became the word that dominated the first half of this year. Then some time in March/April, the Claude Code repository leaked, and I basically locked in. What I was curious about was how does one go about building an effective Agent, and what even is an agent? What makes up context and how are LLM messages handled? So I set out to build my own harness development kit [(mini-agent-kit)](https://github.com/farhan0167/minimal-agent), and in this blog, I'd like to share some of my learnings.

## So what is an Agent?

Before I go over what an agent is, I think it is important to understand how we interact with a language model(LLM for short).

```python
from openai import OpenAI
client = OpenAI()

messages = [
    {"role": "system", "content": "You are a helpful assistant."},
    {"role": "user", "content": "Hello!"}
]

def llm_call(messages):
    completion = client.chat.completions.create(
        model="gpt5",
        messages=messages
    )
    return completion.choices[0].message
```

The above code snippet shows how we go about making an LLM request. At the most basic level, there is a collection of messages made up of a system and user prompt. The LLM would take this collection, and return an assistant message in response to the user prompt. If we wrap this function in a loop:

```python
while True:
    prompt = input("> ")
    messages.append({"role": "user", "content": prompt})
    llm_out = llm_call(messages)
    messages.append(llm_out)
```

We get a very simple chat application, and this is very straight forward. What we can then do is give our chat application a set of tools. And let's use the classic example for tools, getting the weather. Suppose we have some weather API that given a city would return the temperature.

```python
def get_weather(city):
    # pretend this hits a real weather API
    return f"It's 72F and sunny in {city}."
```

To get an LLM to use this API, we define a JSON schema instructing the LLM to look for parameters required by this function:

```python
tools = [
    {
        "type": "function",
        "function": {
            "name": "get_weather",
            "description": "Get the current weather for a given city",
            "parameters": {
                "type": "object",
                "properties": {
                    "city": {
                        "type": "string",
                        "description": "The city to get the weather for"
                    }
                },
                "required": ["city"]
            }
        }
    }
]
```

Next, we pass `tools` into the request:

```python
def llm_call(messages):
    completion = client.chat.completions.create(
        ...
        tools=tools
    )
    return completion.choices[0].message
```

And encode this into the loop to actually run the tool when the model asks for one:

```python

while True:
    prompt = input("> ")
    messages.append({"role": "user", "content": prompt})
    llm_out = llm_call(messages)
    messages.append(llm_out)

    if llm_out.tool_calls:
        for tool_call in llm_out.tool_calls:
            args = json.loads(tool_call.function.arguments)
            result = get_weather(**args)
            messages.append({
                "role": "tool",
                "tool_call_id": tool_call.id,
                "content": result
            })
        llm_out = llm_call(messages)
        messages.append(llm_out)
```

This way, when a user asks, "What is the weather in London?", the model returns a message with `tool_calls` which should have the keywords extracted, i.e London in this case. This way we can then run the `get_weather()` function, append a message back with the response of the API, and our LLM is now able to interact with the outside world.

So what is an agent? What we just did here, is a very simple form of an agent. There are tools to interact with the outside world, and more importantly, a loop. I would, however, be lying to you if I stopped here and claimed this for an agent. So let's dive a bit deeper.

### ReAct

In 2023, the authors Yao, et al.[1], published ReAct agent, short for Reasoning+Action. To summarize their work, what the authors proposed was to equip LM's with chain of thought reasoning and using its reasoning to take actions.

<div class="text-center">
    {% include figure.liquid path="assets/img/2026-06-15-highlight-project/react-prompt.png" alt="ReAct prompt example" class="img-fluid" width="60%" %}
    {% include figure.liquid path="assets/img/2026-06-15-highlight-project/react.png" alt="ReAct example" class="img-fluid" width="60%" caption="Source: Yao et al., <a href=\"https://arxiv.org/pdf/2210.03629\">ReAct: Synergizing Reasoning and Acting in Language Models</a> (2023) [1]" %}
</div>

Consider our example in the previous section, where we ask the LM what the weather is in London. An agent in this case would reason that it needs to get the weather of London by calling on the weather API, and take the action by calling it. Or consider a coding agent: it's primary goal is to solve tasks specified by the user, and it does so by reasoning with its available tools to interact with its environment, and take actions such as writing new code, or editing existing ones. It is important to note that, an agent has a task it generally needs to achieve.

With that intuition in place, here is a more formal definition:

> An Agent is a system that leverages an AI model to interact with its environment in order to achieve a user-defined objective. It combines reasoning, planning, and the execution of actions (often via external tools) to fulfill tasks.
>
> — Hugging Face, [Agents Course: What are Agents?](https://huggingface.co/learn/agents-course/en/unit1/what-are-agents) [2]

### So what does it mean in practice?

Notice that everything the model reasons over — the user's input, its own responses, and the results of any tools it runs — lives in that single `messages` list we kept appending to. Let's give that a name: the **Context**. It's the abstraction for everything that goes into the model on each call, and the agent's whole job is to grow and manage it. With that framing, the loop becomes:

<div>
    {% include figure.liquid path="assets/img/2026-06-15-highlight-project/react-code.png" alt="ReAct pseudocode" class="img-fluid" width="80%" %}
</div>

The model itself is stateless — Context is the only memory it has to work with. It starts as the system prompt and tool schemas, then grows with every user message, assistant response, and tool result. Managing what goes in, and eventually what gets trimmed out, turns out to be the core of building an agent.

## Harness: The Powerful Extras
