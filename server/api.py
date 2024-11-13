from google.cloud import storage, firestore
from flask import Flask, request, jsonify
from google.oauth2 import service_account
import google.generativeai as genai
import typing_extensions as typing
from dotenv import load_dotenv
import os

load_dotenv()
app = Flask(__name__)

genai.configure(api_key=os.environ["GEMINI_API_KEY"])
model = genai.GenerativeModel("gemini-1.5-flash")

credentials = service_account.Credentials.from_service_account_file('./service_account_key.json')
firestore_client = firestore.Client(credentials=credentials)
storage_client = storage.Client(credentials=credentials)

class Education(typing.TypedDict):
    institution: str
    degree: str
    start_date: str
    end_date: str

class Experience(typing.TypedDict):
    company: str
    role: str
    start_date: str
    end_date: str
    responsibilities: str

class Resume(typing.TypedDict):
    name: str
    education: list[Education]
    experience: list[Experience]
    skills: list[str]

class SkillGap(typing.TypedDict):
    skill_gap: str
    description: str
    recommendations: list[str]

class Learning(typing.TypedDict):
    resource_name: str
    link: str
    summary: str

class InterviewQuestions(typing.TypedDict):
    question: str

def parse_resume_url(url):
    path_parts = url.replace("https://storage.googleapis.com/", "").split("/")
    bucket_name = path_parts[0]
    blob_name = "/".join(path_parts[1:])
    return bucket_name, blob_name

def download_resume(bucket_name, blob_name):
    try:
        bucket = storage_client.get_bucket(bucket_name)
        blob = bucket.blob(blob_name)
        resume = blob.download_as_text()
        return resume
    except Exception as e:
        print(f"ERROR: {e}")
        return None

@app.route('/extract_resume', methods=['POST'])
def extract_resume():
    data = request.json
    resume_url = data.get("resumeUrl")
    user_id = data.get("userId")  
    bucket_name, blob_name = parse_resume_url(resume_url)
    resume = download_resume(bucket_name, blob_name)
    resume_prompt = f"""
        Extract relevant details from the following resume content:
        {resume}
    """
    response = model.generate_content(
        resume_prompt,
        generation_config=genai.GenerationConfig(
                response_mime_type="application/json", response_schema=Resume
            ),
    )   
    user_ref = firestore_client.collection('users').document(user_id)
    user_ref.set({
        'name': response['name'],
        'skills': response['skills']
    }, merge=True)
    education_ref = user_ref.collection('education')
    for education in response['education']:
        education_ref.add(education)
    experience_ref = user_ref.collection('experience')
    for experience in response['experience']:
        experience_ref.add(experience)
    return jsonify(response)

@app.route('/analyze_skills_gap', methods=['POST'])
def analyze_skills_gap():
    data = request.json
    user_id = data.get("userId")
    job_id = data.get("jobId")
    if not user_id or not job_id:
        return jsonify({"error": "The user ID and job ID cannot be null."}), 400
    user_ref = firestore_client.collection('users').document(user_id)
    user_doc = user_ref.get()
    if not user_doc.exists:
        return jsonify({"error": "The user data could not be found."}), 404
    education_ref = user_ref.collection('education')
    experience_ref = user_ref.collection('experience')
    education = [doc.to_dict() for doc in education_ref.stream()]
    experience = [doc.to_dict() for doc in experience_ref.stream()]
    skills = user_doc.to_dict().get('skills', [])
    job_ref = user_ref.collection('jobs').document(job_id)
    job_doc = job_ref.get()
    if not job_doc.exists:
        return jsonify({"error": "Job data not found."}), 404
    job = job_doc.to_dict()
    skills_gap_prompt = f"""
        You are an expert career coach. Analyze the following:
        The candidate's education history: {education}\n\n
        The candidate's work experience: {experience}\n\n
        The candidate's skills: {skills}\n\n
        and the job description: {job}\n\n
        Identify at least 3 skill gaps. Give a concise but comprehensive description of the skill gap
        in reference to the candidate's resume as well as the job description. Provide specific recommendations 
        on how to address each skill gap. Ensure that each skill gap, description, and recommendation is specific, actionable,
        and directly relevant to both the job description and the candidate's resume.
    """
    skills_gap_response = model.generate_content(
        skills_gap_prompt,
        generation_config=genai.GenerationConfig(
                response_mime_type="application/json", response_schema=SkillGap
            ),
    )
    job_ref = user_ref.collection('jobs').document(job_id)
    skills_gap_analysis_ref = job_ref.collection('skills_gap_analysis')
    existing_docs = skills_gap_analysis_ref.stream()
    for doc in existing_docs:
        doc.reference.delete()
    for gap in skills_gap_response:
        job_ref.collection('skills_gap_analysis').add({
            'skill_gap': gap.get('skill_gap', ''),
            'description': gap.get('description', ''),
            'recommendations': gap.get('recommendations', []),
        })
    return jsonify(skills_gap_response)

@app.route('/create_learning_pathway', methods=['POST'])
def create_learning_pathway():
    data = request.json
    user_id = data.get("userId")
    job_id = data.get("jobId")
    if not user_id:
        return jsonify({"error": "The user ID cannot be null."}), 400
    user_ref = firestore_client.collection('users').document(user_id)
    user_doc = user_ref.get()
    if not user_doc.exists:
        return jsonify({"error": "User data not found."}), 404
    education_ref = user_ref.collection('education')
    experience_ref = user_ref.collection('experience')
    education = [doc.to_dict() for doc in education_ref.stream()]
    experience = [doc.to_dict() for doc in experience_ref.stream()]
    skills = user_doc.to_dict().get('skills', [])
    job_ref = user_ref.collection('jobs').document(job_id)
    job_doc = job_ref.get()
    if not job_doc.exists:
        return jsonify({"error": "Job data not found."}), 404
    job = job_doc.to_dict()
    learning_prompt = f"""
        You are an expert career coach. Analuze the following:
        The candidate's education history: {education}\n\n
        The candidate's work experience: {experience}\n\n
        The candidate's skills: {skills}\n\n
        and the job description: {job}\n\n
        Identify at least 5 highly relevant resources to help bridge 
        the candidate's skill gaps. For each resource, provide: 
        - a clear title, 
        - a direct link,
        - a concise yet informative summary of the content and how it addresses specific requirements 
        in the job description and the candidate's identified skill gaps.
        Ensure each summary highlights the resource's relevance to specific skills or competencies 
        essential for success in this role.
    """
    learning_response = model.generate_content(
        learning_prompt,
        generation_config=genai.GenerationConfig(
                response_mime_type="application/json", response_schema=Learning
            ),
    )
    job_ref = user_ref.collection('jobs').document(job_id)
    learning_pathway_ref = job_ref.collection('learning_pathway')
    existing_docs = learning_pathway_ref.stream()
    for doc in existing_docs:
        doc.reference.delete()
    for resource in learning_response:
        job_ref.collection('learning_pathway').add({
            'resource_name': resource.get('resource_name', ''),
            'link': resource.get('link', ''),
            'summary': resource.get('summary', ''),
        })
    return jsonify(learning_response)

@app.route('/generate_interview_questions', methods=['POST'])
def generate_interview_questions():
    data = request.json
    user_id = data.get("userId")
    job_id = data.get("jobId")
    if not user_id:
        return jsonify({"error": "The user ID cannot be null."}), 400
    user_ref = firestore_client.collection('users').document(user_id)
    user_doc = user_ref.get()
    if not user_doc.exists:
        return jsonify({"error": "User data not found."}), 404
    education_ref = user_ref.collection('education')
    experience_ref = user_ref.collection('experience')
    education = [doc.to_dict() for doc in education_ref.stream()]
    experience = [doc.to_dict() for doc in experience_ref.stream()]
    skills = user_doc.to_dict().get('skills', [])
    job_ref = user_ref.collection('jobs').document(job_id)
    job_doc = job_ref.get()
    if not job_doc.exists:
        return jsonify({"error": "Job data not found."}), 404
    job = job_doc.to_dict()
    interview_prompt = f"""
        You are a highly experienced interviewer for the hiring company. Based on the following:
        The candidate's education history: {education}\n\n
        The candidate's work experience: {experience}\n\n
        The candidate's skills: {skills}\n\n
        and the job description: {job}\n\n
        Craft 10 targeted interview questions. Focus on assessing the candidate's technical skills, 
        problem-solving abilities, and alignment with the company's culture and values. Each question 
        should be concise, specific, and directly relevant to both the role and the candidate’s experience, 
        allowing them to demonstrate their qualifications and cultural fit effectively.
    """
    interview_response = model.generate_content(
        interview_prompt,
        generation_config=genai.GenerationConfig(
                response_mime_type="application/json", response_schema=InterviewQuestions
            ),
    )
    job_ref = user_ref.collection('jobs').document(job_id)
    questions = [item["question"] for item in interview_response]
    job_ref.set({"interview_questions": questions}, merge=True)
    return jsonify(interview_response)

@app.route('/write_cover_letter', methods=['POST'])
def write_cover_letter():
    data = request.json
    user_id = data.get("userId")
    job_id = data.get("jobId")
    if not user_id:
        return jsonify({"error": "The user ID cannot be null."}), 400
    user_ref = firestore_client.collection('users').document(user_id)
    user_doc = user_ref.get()
    if not user_doc.exists:
        return jsonify({"error": "User data not found."}), 404
    education_ref = user_ref.collection('education')
    experience_ref = user_ref.collection('experience')
    education = [doc.to_dict() for doc in education_ref.stream()]
    experience = [doc.to_dict() for doc in experience_ref.stream()]
    skills = user_doc.to_dict().get('skills', [])
    job_ref = user_ref.collection('jobs').document(job_id)
    job_doc = job_ref.get()
    if not job_doc.exists:
        return jsonify({"error": "Job data not found."}), 404
    job = job_doc.to_dict()
    letter_prompt = f"""
        You are an expert cover letter writer. Compose a professional cover letter 
        based on the following: 
        The candidate's education history: {education}\n\n
        The candidate's work experience: {experience}\n\n
        The candidate's skills: {skills}\n\n
        and the job description: {job}\n\n
        Follow a concise template like this:
        1. Greeting: For example, 'To whom it may concern,'
        2. Introduction: Write a brief introduction, expressing enthusiasm for the 
        role and a short pitch as to why the candidate would be well-suited for the role.
        3. Body: Emphasize a key experiences that align with the job requirements. Highlight 
        relevant skills that demonstrates the candidate's qualifications. Mention a notable 
        achievement or project that showcases concrete impact.
        4. Conclusion: Reaffirm interest in the role, encourage further discussion, and 
        close professionally.
        Ensure that the cover letter is engaging and no more than 500 words. Use clear 
        language and structured bullet points for readability.
    """
    letter_response = model.generate_content(
        letter_prompt,
        generation_config=genai.GenerationConfig(
                response_mime_type="application/json"
            ),
    )
    job_ref = user_ref.collection('jobs').document(job_id)
    job_ref.set({"cover_letter": letter_response}, merge=True)
    return jsonify(letter_response)


if __name__ == '__main__':
    app.run(debug=True)
