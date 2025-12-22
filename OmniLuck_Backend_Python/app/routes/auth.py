from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import httpx
import json
import os


router = APIRouter()

# Config from firebase-config.js
FIREBASE_WEB_API_KEY = "AIzaSyBcZBINsBBcqgyLxzz89oMa--M-RWGlEbw"
FIREBASE_PROJECT_ID = "celestial-fortune-7d9b4"

class LoginRequest(BaseModel):
    email: str
    password: str

@router.post("/login")
async def login(request: LoginRequest):
    email_to_use = request.email
    
    async with httpx.AsyncClient() as client:
        # 1. Resolve Username
        if "@" not in request.email:
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
                query_resp = await client.post(query_url, json=query_payload)
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
            except httpx.RequestError as e:
                print(f"Username query error: {e}")
                raise HTTPException(status_code=404, detail="No account found with this username")

        # 2. Auth with Google
        auth_url = f"https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={FIREBASE_WEB_API_KEY}"
        payload = {
            "email": email_to_use,
            "password": request.password,
            "returnSecureToken": True
        }
        
        try:
            resp = await client.post(auth_url, json=payload)
            
            if resp.status_code != 200:
                error_data = resp.json()
                error_msg = error_data.get("error", {}).get("message", "Login failed")
                if "INVALID_PASSWORD" in error_msg or "EMAIL_NOT_FOUND" in error_msg:
                    raise HTTPException(status_code=401, detail="Invalid email/username or password")
                raise HTTPException(status_code=400, detail=error_msg)
                
            auth_data = resp.json()
            uid = auth_data["localId"]
            id_token = auth_data["idToken"]
            email = auth_data["email"]

            # 3. Fetch Profile
            firestore_url = f"https://firestore.googleapis.com/v1/projects/{FIREBASE_PROJECT_ID}/databases/(default)/documents/users/{uid}"
            headers = {"Authorization": f"Bearer {id_token}"}
            
            fs_resp = await client.get(firestore_url, headers=headers)
            
            profile = {}
            if fs_resp.status_code == 200:
                doc = fs_resp.json()
                fields = doc.get("fields", {})
                for key, value in fields.items():
                    if "stringValue" in value:
                        profile[key] = value["stringValue"]
                    elif "integerValue" in value:
                        profile[key] = int(value["integerValue"])
                    elif "timestampValue" in value:
                        profile[key] = value["timestampValue"]
                    elif "doubleValue" in value:
                        profile[key] = float(value["doubleValue"])
            
            return {
                "success": True, 
                "uid": uid, 
                "email": email, 
                "idToken": id_token, 
                "profile": profile
            }
            
        except httpx.RequestError as e:
            raise HTTPException(status_code=503, detail=f"Network error: {str(e)}")

class SignupRequest(BaseModel):
    username: str
    firstName: str
    middleName: str = ""
    lastName: str
    email: str
    password: str
    dob: str
    birth_place: str = ""
    birth_time: str = ""
    lat: float = 0.0
    lon: float = 0.0
    phoneNumber: str = ""

@router.post("/signup")
async def signup(request: SignupRequest):
    auth_url = f"https://identitytoolkit.googleapis.com/v1/accounts:signUp?key={FIREBASE_WEB_API_KEY}"
    payload = {
        "email": request.email,
        "password": request.password,
        "returnSecureToken": True
    }
    
    async with httpx.AsyncClient() as client:
        try:
            resp = await client.post(auth_url, json=payload)
            
            if resp.status_code != 200:
                error_data = resp.json()
                error_msg = error_data.get("error", {}).get("message", "Signup failed")
                if "EMAIL_EXISTS" in error_msg:
                    raise HTTPException(status_code=400, detail="This email is already registered")
                elif "WEAK_PASSWORD" in error_msg:
                    raise HTTPException(status_code=400, detail="Password should be at least 6 characters")
                raise HTTPException(status_code=400, detail=error_msg)
                
            auth_data = resp.json()
            uid = auth_data["localId"]
            id_token = auth_data["idToken"]
            
            # Create Firestore Doc
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
                    "phoneNumber": {"stringValue": request.phoneNumber},
                    "dob": {"stringValue": request.dob},
                    "birth_place": {"stringValue": request.birth_place},
                    "birth_time": {"stringValue": request.birth_time},
                    "lat": {"doubleValue": request.lat},
                    "lon": {"doubleValue": request.lon}
                }
            }
            
            firestore_url = f"https://firestore.googleapis.com/v1/projects/{FIREBASE_PROJECT_ID}/databases/(default)/documents/users?documentId={uid}"
            headers = {"Authorization": f"Bearer {id_token}", "Content-Type": "application/json"}
            
            fs_resp = await client.post(firestore_url, json=user_data, headers=headers)
            
            if fs_resp.status_code not in [200, 201]:
                print(f"Firestore Create Error: {fs_resp.text}")
                raise HTTPException(status_code=500, detail="Failed to create user profile")
                
            return {
                "success": True,
                "uid": uid,
                "email": request.email,
                "idToken": id_token,
                "message": "Account created successfully"
            }
            
        except httpx.RequestError as e:
            raise HTTPException(status_code=503, detail=f"Network error: {str(e)}")

class ResetPasswordRequest(BaseModel):
    email: str

@router.post("/reset-password")
async def reset_password(request: ResetPasswordRequest):
    auth_url = f"https://identitytoolkit.googleapis.com/v1/accounts:sendOobCode?key={FIREBASE_WEB_API_KEY}"
    payload = {
        "requestType": "PASSWORD_RESET",
        "email": request.email
    }
    
    async with httpx.AsyncClient() as client:
        try:
            resp = await client.post(auth_url, json=payload)
            if resp.status_code != 200:
                error_data = resp.json()
                error_msg = error_data.get("error", {}).get("message", "Reset failed")
                if "EMAIL_NOT_FOUND" in error_msg:
                    raise HTTPException(status_code=404, detail="No account found with this email")
                raise HTTPException(status_code=400, detail=error_msg)
            return {"success": True, "message": "Password reset email sent"}
        except httpx.RequestError as e:
            raise HTTPException(status_code=503, detail=f"Network error: {str(e)}")

class DeleteAccountRequest(BaseModel):
    idToken: str

@router.post("/delete")
async def delete_account(request: DeleteAccountRequest):
    async with httpx.AsyncClient() as client:
        # 1. Lookup UID
        lookup_url = f"https://identitytoolkit.googleapis.com/v1/accounts:lookup?key={FIREBASE_WEB_API_KEY}"
        lookup_resp = await client.post(lookup_url, json={"idToken": request.idToken})
        
        uid = None
        if lookup_resp.status_code == 200:
            data = lookup_resp.json()
            if "users" in data and len(data["users"]) > 0:
                uid = data["users"][0]["localId"]
                
        if uid:
            # 2. Delete Firestore
            fs_url = f"https://firestore.googleapis.com/v1/projects/{FIREBASE_PROJECT_ID}/databases/(default)/documents/users/{uid}"
            await client.delete(fs_url, headers={"Authorization": f"Bearer {request.idToken}"})

        # 3. Delete Auth
        del_url = f"https://identitytoolkit.googleapis.com/v1/accounts:delete?key={FIREBASE_WEB_API_KEY}"
        resp = await client.post(del_url, json={"idToken": request.idToken})
        
        if resp.status_code != 200:
            raise HTTPException(status_code=400, detail="Failed to delete account. Session may be expired.")
            
        return {"success": True, "message": "Account deleted"}


