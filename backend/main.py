import json
import os

from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException, UploadFile, File
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


@app.post("/copycatcher/analyze")
async def copycatcher_analyze(
    file: UploadFile = File(...)
):

    if not file.filename:
        raise HTTPException(
            status_code=400,
            detail="No file selected.",
        )

    filename = file.filename.lower()

    if not filename.endswith((".pdf", ".docx")):
        raise HTTPException(
            status_code=400,
            detail="Only PDF and DOCX files are supported.",
        )

    try:
        file_bytes = await file.read()

        if not file_bytes:
            raise HTTPException(
                status_code=400,
                detail="Uploaded file is empty.",
            )

        if filename.endswith(".pdf"):
            from io import BytesIO
            from pypdf import PdfReader

            reader = PdfReader(BytesIO(file_bytes))

            text_parts = []

            for page in reader.pages:
                page_text = page.extract_text() or ""
                text_parts.append(page_text)

            document_text = "\n".join(text_parts)

        else:
            from io import BytesIO
            from docx import Document

            document = Document(BytesIO(file_bytes))

            text_parts = [
                paragraph.text
                for paragraph in document.paragraphs
                if paragraph.text.strip()
            ]

            document_text = "\n".join(text_parts)

        if not document_text.strip():
            raise HTTPException(
                status_code=400,
                detail="Could not extract text from the document.",
            )

        # Keep prompt size reasonable.
        document_text = document_text[:20000]

        prompt = f"""
You are an AI academic originality assistant for a college app.

Analyze the following student assignment/document.

DOCUMENT TEXT:
{document_text}

Estimate:
1. Similarity with commonly available/repeated academic content.
2. Originality of the writing.
3. Probability that the writing appears AI-generated.

Important:
- These are estimates, not definitive proof of plagiarism or AI authorship.
- Do not claim that a document is definitely AI-generated.
- Give practical recommendations.
- Return ONLY valid JSON.

Use exactly this structure:

{{
    "similarity_percentage": 0,
    "originality_percentage": 0,
    "ai_percentage": 0,
    "summary": "",
    "matched_areas": [],
    "recommendations": []
}}

Rules:
- All percentages must be between 0 and 100.
- similarity_percentage + originality_percentage should equal 100.
- matched_areas must be an array of strings.
- recommendations must be an array of strings.
"""

        response = client.responses.create(
            model="gpt-5.6-luna",
            input=prompt,
        )

        result = json.loads(response.output_text)

        return {
            "similarity_percentage": result.get(
                "similarity_percentage",
                0,
            ),
            "originality_percentage": result.get(
                "originality_percentage",
                0,
            ),
            "ai_percentage": result.get(
                "ai_percentage",
                0,
            ),
            "summary": result.get(
                "summary",
                "",
            ),
            "matched_areas": result.get(
                "matched_areas",
                [],
            ),
            "recommendations": result.get(
                "recommendations",
                [],
            ),
        }

    except HTTPException:
        raise

    except json.JSONDecodeError:
        raise HTTPException(
            status_code=500,
            detail="AI returned invalid JSON.",
        )

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"CopyCatcher AI error: {str(e)}",
        )