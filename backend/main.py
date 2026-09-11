import json
import os

from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from openai import OpenAI
from pydantic import BaseModel


load_dotenv()

api_key = os.getenv("OPENAI_API_KEY")

if not api_key:
    raise RuntimeError("OPENAI_API_KEY is missing from .env")

client = OpenAI(api_key=api_key)

app = FastAPI(
    title="CampusX AI Backend",
    version="1.0.0",
)


class SkillBridgeRequest(BaseModel):
    resume_text: str
    job_description: str


@app.get("/")
def home():
    return {
        "project": "CampusX",
        "status": "Backend is running",
        "message": "CampusX AI Backend 🚀",
    }


@app.get("/health")
def health():
    return {
        "status": "ok",
    }


@app.post("/skillbridge/analyze")
def analyze_skillbridge(request: SkillBridgeRequest):
    resume = request.resume_text.strip()
    job_description = request.job_description.strip()

    if not resume or not job_description:
        raise HTTPException(
            status_code=400,
            detail="Resume text and job description are required.",
        )

    prompt = f"""
You are the SkillBridge AI module of CampusX.

Analyze the student's resume against the job description.

Return ONLY valid JSON in exactly this structure:

{{
  "match_percentage": 0,
  "matched_skills": [],
  "missing_skills": [],
  "roadmap": [
    {{
      "week": 1,
      "title": "",
      "skills": []
    }},
    {{
      "week": 2,
      "title": "",
      "skills": []
    }},
    {{
      "week": 3,
      "title": "",
      "skills": []
    }},
    {{
      "week": 4,
      "title": "",
      "skills": []
    }}
  ]
}}

Rules:
- match_percentage must be an integer from 0 to 100.
- matched_skills must contain skills found in both the resume and job description.
- missing_skills must contain important job skills missing from the resume.
- roadmap must give a practical 4-week learning plan.
- Do not invent experience for the student.
- Return JSON only.
- Do not use markdown code fences.

RESUME:
{resume}

JOB DESCRIPTION:
{job_description}
"""

    try:
        response = client.responses.create(
            model="gpt-5.6-luna",
            input=prompt,
        )

        result_text = response.output_text.strip()

        # Remove accidental markdown code fences if AI adds them.
        if result_text.startswith("```"):
            result_text = result_text.replace("```json", "", 1)
            result_text = result_text.replace("```", "", 1).strip()

        ai_result = json.loads(result_text)

        if not isinstance(ai_result, dict):
            raise ValueError("AI returned an invalid JSON object.")

        match_percentage = ai_result.get("match_percentage", 0)
        matched_skills = ai_result.get("matched_skills", [])
        missing_skills = ai_result.get("missing_skills", [])
        roadmap = ai_result.get("roadmap", [])

        return {
            "status": "analysis_complete",
            "match_percentage": match_percentage,
            "matched_skills": matched_skills,
            "missing_skills": missing_skills,
            "roadmap": roadmap,
        }

    except json.JSONDecodeError:
        raise HTTPException(
            status_code=500,
            detail="AI returned invalid JSON.",
        )

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"AI analysis failed: {str(e)}",
        )