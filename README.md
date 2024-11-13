# virgo

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
4. Start the server by running `python api.py`.
### Client
6. Navigate back to the parent directory.
7. Run `flutter pub get` to install all dependencies.
8. Run `flutter run -d chrome --web-renderer html` to start the web application.
