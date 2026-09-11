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


# ============================================================
# REQUEST MODELS
# ============================================================

class SkillBridgeRequest(BaseModel):
    resume_text: str
    job_description: str


class ExamWarriorRequest(BaseModel):
    subject: str
    unit: str
    topic: str
    difficulty: str


class SafetyAIRequest(BaseModel):
    report_type: str
    description: str
    latitude: float
    longitude: float
    recent_reports: list[dict] = []


class AttendanceAIRequest(BaseModel):
    student_name: str
    present_count: int
    absent_count: int
    total_classes: int
    recent_records: list[dict] = []


class TeacherAttendanceAIRequest(BaseModel):
    class_name: str
    total_students: int
    students: list[dict]
    recent_summary: list[dict] = []


# ============================================================
# BASIC ROUTES
# ============================================================

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


# ============================================================
# SKILLBRIDGE AI
# ============================================================

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


# ============================================================
# EXAMWARRIOR AI
# ============================================================

@app.post("/examwarrior/generate")
def examwarrior_generate(request: ExamWarriorRequest):

    prompt = f"""
You are an AI question generator for a B.Tech college
exam preparation app.

Generate ONE useful exam-practice question.

Subject: {request.subject}
Unit: {request.unit}
Topic: {request.topic}
Difficulty: {request.difficulty}

Requirements:

- The question must be relevant to the subject, unit and topic.
- Match the requested difficulty.
- Make it suitable for a B.Tech student.
- Do not provide the answer.
- Do not add unnecessary explanation.

Return ONLY valid JSON:

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


# ============================================================
# COPYCATCHER AI
# ============================================================

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

        document_text = document_text[:20000]

        prompt = f"""
You are an AI academic originality assistant for a college app.

Analyze the following student assignment/document.

DOCUMENT TEXT:

{document_text}

Estimate:

1. Similarity with commonly available or repeated academic content.
2. Originality of the writing.
3. Probability that the writing appears AI-generated.

Important:

- These are estimates, not definitive proof.
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


# ============================================================
# CAMPUSSHIELD AI
# ============================================================

@app.post("/safety/analyze")
def safety_analyze(request: SafetyAIRequest):

    reports_text = json.dumps(
        request.recent_reports[:50],
        ensure_ascii=False,
    )

    prompt = f"""
You are CampusShield AI, an AI safety-analysis assistant
for a college campus.

Analyze this campus safety report.

Report type:
{request.report_type}

Description:
{request.description}

Location:
Latitude: {request.latitude}
Longitude: {request.longitude}

Recent reports:
{reports_text}

Return ONLY valid JSON:

{{
    "risk_score": 0,
    "risk_level": "Low",
    "category": "",
    "severity": "",
    "reason": "",
    "recommended_action": "",
    "time_risk": ""
}}

Rules:

- risk_score must be between 0 and 100.
- risk_level must be Low, Medium, High, or Critical.
- severity must be Low, Medium, High, or Critical.
- category should describe the main safety issue.
- reason should briefly explain the estimated risk.
- recommended_action should give a practical action for
  campus staff.
- time_risk should mention a time-related concern only when
  supported by the provided information.
- Do not claim certainty.
- This is a risk estimate, not a guarantee of safety.
"""

    try:
        response = client.responses.create(
            model="gpt-5.6-luna",
            input=prompt,
        )

        result = json.loads(response.output_text)

        return {
            "risk_score": result.get("risk_score", 0),
            "risk_level": result.get("risk_level", "Low"),
            "category": result.get("category", ""),
            "severity": result.get("severity", "Low"),
            "reason": result.get("reason", ""),
            "recommended_action": result.get(
                "recommended_action",
                "",
            ),
            "time_risk": result.get("time_risk", ""),
        }

    except json.JSONDecodeError:
        raise HTTPException(
            status_code=500,
            detail="Safety AI returned invalid JSON.",
        )

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Safety AI error: {str(e)}",
        )


# ============================================================
# STUDENT ATTENDANCE AI
# ============================================================

@app.post("/attendance/student-insight")
def attendance_student_insight(
    request: AttendanceAIRequest
):

    if request.total_classes <= 0:
        raise HTTPException(
            status_code=400,
            detail="Total classes must be greater than zero.",
        )

    attendance_percentage = (
        request.present_count / request.total_classes
    ) * 100

    records_text = json.dumps(
        request.recent_records[:50],
        ensure_ascii=False,
    )

    prompt = f"""
You are CampusX Attendance AI.

Analyze a student's attendance data and provide a simple
academic attendance insight.

Student:
{request.student_name}

Present classes:
{request.present_count}

Absent classes:
{request.absent_count}

Total classes:
{request.total_classes}

Current attendance percentage:
{attendance_percentage:.1f}%

Recent attendance records:
{records_text}

Return ONLY valid JSON:

{{
    "attendance_percentage": 0,
    "status": "Good",
    "risk_level": "Low",
    "insight": "",
    "recommendation": "",
    "trend": ""
}}

Rules:

- attendance_percentage must be between 0 and 100.
- status must be Good, Attention, or Critical.
- risk_level must be Low, Medium, or High.
- Give practical and non-alarming advice.
- Do not invent attendance records.
"""

    try:
        response = client.responses.create(
            model="gpt-5.6-luna",
            input=prompt,
        )

        result = json.loads(response.output_text)

        return {
            "attendance_percentage": result.get(
                "attendance_percentage",
                round(attendance_percentage, 1),
            ),
            "status": result.get(
                "status",
                "Good",
            ),
            "risk_level": result.get(
                "risk_level",
                "Low",
            ),
            "insight": result.get(
                "insight",
                "",
            ),
            "recommendation": result.get(
                "recommendation",
                "",
            ),
            "trend": result.get(
                "trend",
                "",
            ),
        }

    except json.JSONDecodeError:
        raise HTTPException(
            status_code=500,
            detail="Attendance AI returned invalid JSON.",
        )

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Attendance AI error: {str(e)}",
        )


# ============================================================
# TEACHER ATTENDANCE AI
# ============================================================

@app.post("/attendance/teacher-analytics")
def attendance_teacher_analytics(
    request: TeacherAttendanceAIRequest
):

    students_text = json.dumps(
        request.students[:100],
        ensure_ascii=False,
    )

    summary_text = json.dumps(
        request.recent_summary[:50],
        ensure_ascii=False,
    )

    prompt = f"""
You are CampusX Attendance AI for teachers.

Analyze the attendance of a college class.

Class:
{request.class_name}

Total students:
{request.total_students}

Student attendance data:
{students_text}

Recent class summary:
{summary_text}

Return ONLY valid JSON:

{{
    "class_status": "Good",
    "overall_percentage": 0,
    "low_attendance_students": [],
    "high_attendance_students": [],
    "insight": "",
    "recommendation": ""
}}

Rules:

- overall_percentage must be between 0 and 100.
- class_status must be Good, Attention, or Critical.
- low_attendance_students must contain student names or
  identifiers supplied in the input.
- Do not invent students.
- Give a concise teacher-friendly summary.
- Recommendations should focus on attendance improvement.
"""

    try:
        response = client.responses.create(
            model="gpt-5.6-luna",
            input=prompt,
        )

        result = json.loads(response.output_text)

        return {
            "class_status": result.get(
                "class_status",
                "Good",
            ),
            "overall_percentage": result.get(
                "overall_percentage",
                0,
            ),
            "low_attendance_students": result.get(
                "low_attendance_students",
                [],
            ),
            "high_attendance_students": result.get(
                "high_attendance_students",
                [],
            ),
            "insight": result.get(
                "insight",
                "",
            ),
            "recommendation": result.get(
                "recommendation",
                "",
            ),
        }

    except json.JSONDecodeError:
        raise HTTPException(
            status_code=500,
            detail="Teacher Attendance AI returned invalid JSON.",
        )

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Teacher Attendance AI error: {str(e)}",
        )