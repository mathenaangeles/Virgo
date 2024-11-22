# Virgo

Virgo is an AI-powered app that with a highly customizable suite of tools to assist users in their job-seeking journey. It aligns the career goals of each applicant with actionable insights. The app has several features that empowers them to present their best selves to their future employers. The **Gemini** model analyzes their resumes, as well as relevant details of the jobs there are targeting to generate the following:

- A comprehensive **skills gap analysis** that offers clear insights into the areas that they need to improve on and actionable recommendations on how to up-skill themselves accordingly
- Tailored **learning pathways** that will enable them to acquire the skills they need to excel
- **Interview questions** to simulate the job application process and to allow them to anticipate employer expectations
- A customizable professional **cover letter** to help them stand out in the competitive job market Virgo serves as a mentor, a coach, and a guide, helping users make informed decisions to unlock new career opportunities.

## Prerequisites
- [Flutter](https://docs.flutter.dev)
- [Firebase]()
- [Gemini API]()
- [Python]()

## Getting Started
### Server
1. In the `server` directory, run `python -m venv .venv` to create a virtual environment.
2. Run `source .venv/bin/activate` to activate your virtual environment.
3. Run `pip install -r requirements.txt` to install all dependencies.
4. Create a `.env` file with the following variables:  
```
GEMINI_API_KEY = <YOUR_GEMINI_API_KEY>
FLASK_APP = "api.py"
```
5. Add your `service_account_key.json` from the **Google Cloud Console** into the `server` directory.
6. Start the server by running `python api.py`.
### Client
7. Navigate back to the parent directory.
8. Run `flutter pub get` to install all dependencies.
9. Run `flutter run -d chrome --web-renderer html` to start the web application.
