#
# This snippet uses Ollama via the Open WebUI
#
import os
from dotenv import load_dotenv
from openai import OpenAI

load_dotenv(override=True)

API_URL = os.getenv('OLLAMA_BASE_URL')
API_KEY = "ollama"
MODEL_NAME = "gpt-oss:20b"

system_prompt = "You are a Swift developer. You are given a task to write a function that will take a list of numbers and return the sum of the numbers."
user_prompt = """
    Write a function that will take a list of numbers and return the sum of the numbers.
"""

messages = [
    {"role": "system", "content": system_prompt},
    {"role": "user", "content": user_prompt}
]

openai = OpenAI(base_url=API_URL, api_key=API_KEY)

response = openai.chat.completions.create(model=MODEL_NAME, messages=messages)
response.choices[0].message.content

print(response.choices[0].message.content)