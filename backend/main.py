from fastapi import FastAPI
from pydantic import BaseModel

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
    resume = request.resume_text.lower()
    job = request.job_description.lower()

    skills = [
        "python",
        "sql",
        "flutter",
        "dart",
        "firebase",
        "data analysis",
        "machine learning",
        "git",
    ]

    matched_skills = [
        skill for skill in skills
        if skill in resume and skill in job
    ]

    missing_skills = [
        skill for skill in skills
        if skill in job and skill not in resume
    ]

    total_job_skills = len(
        [skill for skill in skills if skill in job]
    )

    if total_job_skills == 0:
        match_percentage = 0
    else:
        match_percentage = round(
            len(matched_skills) / total_job_skills * 100
        )

    return {
        "match_percentage": match_percentage,
        "matched_skills": matched_skills,
        "missing_skills": missing_skills,
        "status": "analysis_complete",
    }