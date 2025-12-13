from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import requests
import json

router = APIRouter()

# Config from firebase-config.js
FIREBASE_WEB_API_KEY = "AIzaSyBcZBINsBBcqgyLxzz89oMa--M-RWGlEbw"
FIREBASE_PROJECT_ID = "celestial-fortune-7d9b4"

class LoginRequest(BaseModel):
    email: str
    password: str

@router.post("/login")
async def login(request: LoginRequest):
    # 1. Resolve username to email if needed (like webapp does)
    email_to_use = request.email
    
    if "@" not in request.email:
        # Input is likely a username, query Firestore to find email
        # We need to search without auth token, so use public API endpoint
        # Query: /v1/projects/{projectId}/databases/(default)/documents/users?where...
        # Actually, Firestore REST API doesn't support WHERE queries without auth easily
        # Let's use runQuery endpoint instead
        
        query_url = f"https://firestore.googleapis.com/v1/projects/{FIREBASE_PROJECT_ID}/databases/(default)/documents:runQuery"
        query_payload = {
            "structuredQuery": {
                "from": [{"collectionId": "users"}],
                "where": {
                    "fieldFilter": {
                        "field": {"fieldPath": "username"},
                        "op": "EQUAL",
                        "value": {"stringValue": request.email}
                    }
                },
                "limit": 1
            }
        }
        
        try:
            query_resp = requests.post(query_url, json=query_payload)
            if query_resp.status_code == 200:
                results = query_resp.json()
                if results and len(results) > 0 and "document" in results[0]:
                    doc = results[0]["document"]
                    fields = doc.get("fields", {})
                    if "email" in fields and "stringValue" in fields["email"]:
                        email_to_use = fields["email"]["stringValue"]
                    else:
                        raise HTTPException(status_code=404, detail="No account found with this username")
                else:
                    raise HTTPException(status_code=404, detail="No account found with this username")
            else:
                raise HTTPException(status_code=404, detail="No account found with this username")
        except requests.RequestException:
            raise HTTPException(status_code=404, detail="No account found with this username")
    
    # 2. Verify Password via Google Identity Toolkit
    auth_url = f"https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={FIREBASE_WEB_API_KEY}"
    payload = {
        "email": email_to_use,
        "password": request.password,
        "returnSecureToken": True
    }
    
    try:
        resp = requests.post(auth_url, json=payload)
        
        if resp.status_code != 200:
            error_data = resp.json()
            error_msg = error_data.get("error", {}).get("message", "Login failed")
            print(f"Auth Error: {error_msg}")
            
            if "INVALID_PASSWORD" in error_msg or "EMAIL_NOT_FOUND" in error_msg:
                raise HTTPException(status_code=401, detail="Invalid email/username or password")
            raise HTTPException(status_code=400, detail=error_msg)
            
        auth_data = resp.json()
        uid = auth_data["localId"]
        id_token = auth_data["idToken"]
        email = auth_data["email"]
        
        # 2. Fetch User Profile from Firestore via REST API
        # GET https://firestore.googleapis.com/v1/projects/{projectId}/databases/(default)/documents/users/{uid}
        firestore_url = f"https://firestore.googleapis.com/v1/projects/{FIREBASE_PROJECT_ID}/databases/(default)/documents/users/{uid}"
        headers = {"Authorization": f"Bearer {id_token}"}
        
        fs_resp = requests.get(firestore_url, headers=headers)
        
        profile = {}
        if fs_resp.status_code == 200:
            doc = fs_resp.json()
            # Firestore REST returns fields in a specific format: {"fields": {"name": {"stringValue": "..."}}}
            # We need to flatten it.
            fields = doc.get("fields", {})
            for key, value in fields.items():
                # Extract the first value (stringValue, integerValue, etc.)
                # This is a crude simplifiction but works for standard fields
                if "stringValue" in value:
                    profile[key] = value["stringValue"]
                elif "integerValue" in value:
                    profile[key] = int(value["integerValue"])
                elif "timestampValue" in value:
                    profile[key] = value["timestampValue"]
                elif "doubleValue" in value:
                    profile[key] = float(value["doubleValue"])
                # Add other types as needed
                
        else:
            print(f"Firestore Fetch Warning ({fs_resp.status_code}): {fs_resp.text}")
            
        return {
            "success": True,
            "uid": uid,
            "email": email,
            "idToken": id_token,
            "profile": profile
        }

    except requests.RequestException as e:
         raise HTTPException(status_code=503, detail=f"Network error: {str(e)}")

class SignupRequest(BaseModel):
    username: str
    firstName: str
    middleName: str = ""
    lastName: str
    email: str
    password: str
    dob: str  # "YYYY-MM-DD"
    birth_place: str = ""
    birth_time: str = ""
    lat: float = 0.0
    lon: float = 0.0

@router.post("/signup")
async def signup(request: SignupRequest):
    # 1. Create user with Firebase Auth
    auth_url = f"https://identitytoolkit.googleapis.com/v1/accounts:signUp?key={FIREBASE_WEB_API_KEY}"
    payload = {
        "email": request.email,
        "password": request.password,
        "returnSecureToken": True
    }
    
    try:
        resp = requests.post(auth_url, json=payload)
        
        if resp.status_code != 200:
            error_data = resp.json()
            error_msg = error_data.get("error", {}).get("message", "Signup failed")
            print(f"Signup Error: {error_msg}")
            
            if "EMAIL_EXISTS" in error_msg:
                raise HTTPException(status_code=400, detail="This email is already registered")
            elif "WEAK_PASSWORD" in error_msg:
                raise HTTPException(status_code=400, detail="Password should be at least 6 characters")
            raise HTTPException(status_code=400, detail=error_msg)
            
        auth_data = resp.json()
        uid = auth_data["localId"]
        id_token = auth_data["idToken"]
        
        # 2. Create User Document in Firestore
        full_name = f"{request.firstName} {request.middleName + ' ' if request.middleName else ''}{request.lastName}"
        
        user_data = {
            "fields": {
                "uid": {"stringValue": uid},
                "username": {"stringValue": request.username},
                "email": {"stringValue": request.email},
                "name": {"stringValue": full_name},
                "firstName": {"stringValue": request.firstName},
                "middleName": {"stringValue": request.middleName},
                "lastName": {"stringValue": request.lastName},
                "dob": {"stringValue": request.dob},
                "birth_place": {"stringValue": request.birth_place},
                "birth_time": {"stringValue": request.birth_time},
                "lat": {"doubleValue": request.lat},
                "lon": {"doubleValue": request.lon}
            }
        }
        
        firestore_url = f"https://firestore.googleapis.com/v1/projects/{FIREBASE_PROJECT_ID}/databases/(default)/documents/users?documentId={uid}"
        headers = {"Authorization": f"Bearer {id_token}", "Content-Type": "application/json"}
        
        fs_resp = requests.post(firestore_url, json=user_data, headers=headers)
        
        if fs_resp.status_code not in [200, 201]:
            print(f"Firestore Create Error ({fs_resp.status_code}): {fs_resp.text}")
            raise HTTPException(status_code=500, detail="Failed to create user profile")
            
        return {
            "success": True,
            "uid": uid,
            "email": request.email,
            "idToken": id_token,
            "message": "Account created successfully"
        }
        
    except requests.RequestException as e:
        raise HTTPException(status_code=503, detail=f"Network error: {str(e)}")
