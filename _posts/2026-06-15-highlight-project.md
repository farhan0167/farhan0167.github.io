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

In 2023, Yao et al. [1] published ReAct, short for Reasoning + Action. Their key idea was to interleave reasoning traces with actions: the model verbalizes a thought, takes an action, observes the result, and uses that observation to inform its next thought, repeating this cycle until the task is done.

<div class="text-center">
    {% include figure.liquid path="assets/img/2026-06-15-highlight-project/react-prompt.png" alt="ReAct prompt example" class="img-fluid" width="60%" %}
    {% include figure.liquid path="assets/img/2026-06-15-highlight-project/react.png" alt="ReAct example" class="img-fluid" width="60%" caption="Source: Yao et al., <a href=\"https://arxiv.org/pdf/2210.03629\">ReAct: Synergizing Reasoning and Acting in Language Models</a> (2023) [1]" %}
</div>

Consider our example in the previous section, where we ask the LLM what the weather is in London. An agent in this case would reason that it needs to get the weather of London by calling on the weather API(which is available to it), and take the action by calling it. Or consider a coding agent: its primary goal is to solve coding tasks specified by the user, and it does so by repeatedly reasoning about what to do next and acting on its environment via tools: writing new code, running tests, or editing existing files, until the task is done. 

It is important to note that an agent has a task it generally needs to achieve. It accomplishes this task by reasoning at each turn about what it needs to do, which is generally to invoke one of its available tools. So as not to conflate the two terms, it's worth noting the distinction between the Agent and the LLM: the Large Language Model is what possesses the ability to reason and recognize that it needs to invoke a tool; the Agent is the abstraction that wraps the LLM with a task and a loop to accomplish that goal.

With that intuition in place, here is a more formal definition:

> An Agent is a system that leverages an AI model to interact with its environment in order to achieve a user-defined objective. It combines reasoning, planning, and the execution of actions (often via external tools) to fulfill tasks.
>
> — Hugging Face, [Agents Course: What are Agents?](https://huggingface.co/learn/agents-course/en/unit1/what-are-agents) [2]

### So what does it mean in practice?

To piece everything together, let us first revisit the earlier code we drew up:

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

Even though we previously called this an agent loop, the key thing that is missing here, is the ability for the agent to finish a task. Here, we make one model call, which might decide to invoke a tool, call it and make one final model call. This is problematic because, reasoning and action can happen over many steps, and not just one. The other thing, we also want to do is add a layer of abstraction. Earlier we learnt that the way to interact with a LLM is to pass in a `messages` list, and we also see that, every model output including tool call and its invocation outputs are all appended back to the list. We'll give this a name: the **Context**. It's the abstraction for everything that goes into the model on each call/turn/step, and the agent's whole job is to grow and manage it. With these framings, the loop becomes:

<div>
    {% include figure.liquid path="assets/img/2026-06-15-highlight-project/react-code.svg" alt="ReAct pseudocode" class="img-fluid" width="100%" %}
</div>

We now have an outer loop, which is largely responsible for taking a user input, i.e a task, and an inner loop that performs the reason->act->observe cycle until the task is accomplished. And just like before, within the inner loop, we have a for-loop that goes over every `tool_call` the model issued which is then passed into the process that will execute the tool call. Throughout this cycle, we now maintain this Context object that simply captures the following: the system prompt, tool definitions, user input, tool call and results, and a final output. It is worth calling out, however, that this Context object(and as Claude would say it) is loadbearing. How one designs the Context determines the following:

- What the agent needs to accomplish, i.e., coding, research, etc.
- What environment is the agent operating in? Is there a git repo, or is there sensitive information that needs redaction before passing it to a model.
- What the LLM sees on each turn. Does it see the whole history, a compacted version, or a sliding window?
- Does it keep all past tool results or surgically keep the important ones.
- And many more

The important thing to understand is that an agent has agency and so does the designer of the system who dictates how the agent will interact with the environment. 



## Harness: The Powerful Extras

this will eventually be filled out

## References

[1] Yao, S., Zhao, J., Yu, D., Du, N., Shafran, I., Narasimhan, K., & Cao, Y. (2023). *ReAct: Synergizing Reasoning and Acting in Language Models*. International Conference on Learning Representations (ICLR). [https://arxiv.org/abs/2210.03629](https://arxiv.org/abs/2210.03629)

[2] Hugging Face. (n.d.). *Agents Course: What are Agents?* [https://huggingface.co/learn/agents-course/en/unit1/what-are-agents](https://huggingface.co/learn/agents-course/en/unit1/what-are-agents)
