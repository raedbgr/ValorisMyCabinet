import logging
import os
from pathlib import Path

import firebase_admin
from firebase_admin import credentials, firestore, storage, auth

logger = logging.getLogger(__name__)

class FirebaseService:
    def __init__(self):
        self.db = None
        self.bucket = None
        self._initialized = False

    def initialize(self):
        """Initialize Firebase Admin SDK."""
        if self._initialized:
            return

        # Check if already initialized by another part of the app
        try:
            firebase_admin.get_app()
            self.db = firestore.client()
            self.bucket = storage.bucket()
            self._initialized = True
            logger.info("Firebase already initialized, skipping...")
            return
        except ValueError:
            pass # Not initialized yet

        # Path to service account key
        # We check multiple locations for convenience
        key_locations = [
            Path("serviceAccountKey.json"),
            Path("api/serviceAccountKey.json"),
            Path("../serviceAccountKey.json")
        ]
        
        cert_path = None
        for loc in key_locations:
            if loc.exists():
                cert_path = loc
                break
        
        if not cert_path:
            logger.error("Firebase serviceAccountKey.json NOT FOUND. Firestore will be unavailable.")
            return

        try:
            cred = credentials.Certificate(str(cert_path))
            
            # Note: You should replace 'your-project-id.appspot.com' with your real bucket name
            firebase_admin.initialize_app(cred, {
                'storageBucket': os.getenv("FIREBASE_STORAGE_BUCKET")
            })
            
            self.db = firestore.client()
            self.bucket = storage.bucket()
            self._initialized = True
            logger.info(f"Firebase successfully initialized using {cert_path}")
        except Exception as e:
            logger.error(f"Failed to initialize Firebase: {e}")

    def get_db(self):
        if not self._initialized:
            self.initialize()
        return self.db

    def get_bucket(self):
        if not self._initialized:
            self.initialize()
        return self.bucket

    async def verify_token(self, id_token: str):
        """Verify Firebase ID Token from frontend."""
        try:
            decoded_token = auth.verify_id_token(id_token)
            return decoded_token
        except Exception as e:
            logger.error(f"Token verification failed: {e}")
            return None

    def send_push_notification(self, token: str, title: str, body: str, data: dict = None):
        """Send an FCM push notification to a specific device token."""
        if not self._initialized:
            self.initialize()
            
        try:
            from firebase_admin import messaging
            
            # Convert all data values to strings (FCM requirement)
            str_data = {k: str(v) for k, v in data.items()} if data else {}
            
            message = messaging.Message(
                notification=messaging.Notification(
                    title=title,
                    body=body,
                ),
                data=str_data,
                token=token,
            )
            
            response = messaging.send(message)
            logger.info(f"Successfully sent push notification to {token[:10]}... Response: {response}")
            return response
        except Exception as e:
            logger.error(f"Error sending push notification: {e}")
            return None

    def get_client_fcm_token(self, client_id: str):
        """Retrieve FCM token for a given client from Firestore."""
        db = self.get_db()
        if not db:
            return None
        
        # Check clients collection
        doc_ref = db.collection("clients").document(client_id)
        doc = doc_ref.get()
        if doc.exists:
            data = doc.to_dict()
            if "fcmToken" in data:
                return data["fcmToken"]
            
            # If token is on the user document
            user_id = data.get("userId")
            if user_id:
                user_doc = db.collection("users").document(user_id).get()
                if user_doc.exists:
                    return user_doc.to_dict().get("fcmToken")
                    
        return None

# Singleton instance
fb_service = FirebaseService()
