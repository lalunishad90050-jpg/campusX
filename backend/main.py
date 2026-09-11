import json
import os

from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from openai import OpenAI
from pydantic import BaseModel

load_dotenv()

app = FastAPI(title="CampusX Backend")

api_key = os.getenv("OPENAI_API_KEY")

if not api_key:
    raise RuntimeError("OPENAI_API_KEY is not configured.")

client = OpenAI(api_key=api_key)


class SkillBridgeRequest(BaseModel):
    resume_text: str
    job_description: str


class ExamWarriorRequest(BaseModel):
    subject: str
    unit: str
    topic: str
    difficulty: str


@app.get("/")
def root():
    return {
        "message": "CampusX Backend is running 🚀"
    }


@app.get("/health")
def health():
    return {
        "status": "ok"
    }


@app.post("/skillbridge/analyze")
def skillbridge_analyze(request: SkillBridgeRequest):
    prompt = f"""
You are an AI career assistant for a college student.

Analyze the resume against the job description.

Resume:
{request.resume_text}

Job Description:
{request.job_description}

Return ONLY valid JSON in this exact structure:

{{
  "match_percentage": 0,
  "matched_skills": [],
  "missing_skills": [],
  "roadmap": [
    {{
      "week": 1,
      "title": "",
      "tasks": []
    }},
    {{
      "week": 2,
      "title": "",
      "tasks": []
    }},
    {{
      "week": 3,
      "title": "",
      "tasks": []
    }},
    {{
      "week": 4,
      "title": "",
      "tasks": []
    }}
  ]
}}

match_percentage must be between 0 and 100.
matched_skills and missing_skills must be arrays of strings.
The roadmap must contain exactly 4 weeks.
"""

    try:
        response = client.responses.create(
            model="gpt-5.6-luna",
            input=prompt,
        )

        result = json.loads(response.output_text)

        return result

    except json.JSONDecodeError:
        raise HTTPException(
            status_code=500,
            detail="AI returned invalid JSON.",
        )

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"SkillBridge AI error: {str(e)}",
        )


@app.post("/examwarrior/generate")
def examwarrior_generate(request: ExamWarriorRequest):
    prompt = f"""
You are an AI question generator for a B.Tech college exam preparation app.

Generate ONE useful exam-practice question.

Subject: {request.subject}
Unit: {request.unit}
Topic: {request.topic}
Difficulty: {request.difficulty}

Requirements:
- The question must be relevant to the given subject, unit and topic.
- Match the requested difficulty.
- Make it suitable for a B.Tech student.
- Do not provide the answer.
- Do not add unnecessary explanation.

Return ONLY valid JSON in this exact format:

{{
  "question": "Your generated question here"
}}
"""

    try:
        response = client.responses.create(
            model="gpt-5.6-luna",
            input=prompt,
        )

        result = json.loads(response.output_text)

        question = result.get("question")

        if not question:
            raise HTTPException(
                status_code=500,
                detail="AI returned an empty question.",
            )

        return {
            "question": question
        }

    except json.JSONDecodeError:
        raise HTTPException(
            status_code=500,
            detail="AI returned invalid JSON.",
        )

    except HTTPException:
        raise

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"ExamWarrior AI error: {str(e)}",
        )