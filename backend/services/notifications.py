import firebase_admin
from firebase_admin import credentials, messaging

# Note: In a real app, initialize this with your actual Firebase service account JSON
# cred = credentials.Certificate("path/to/serviceAccountKey.json")
# firebase_admin.initialize_app(cred)

def send_push_notification_to_students(students, deal_id: int, vendor_name: str):
    """
    Takes a list of student database objects and sends an FCM push notification.
    """
    if not students:
        return

    # In reality, the Student model would have an 'fcm_token' column
    # tokens = [student.fcm_token for student in students if student.fcm_token]
    
    # Mocking the payload for demonstration
    message_title = "Mystery Box Alert! 🍱"
    message_body = f"{vendor_name} just listed a surplus Mystery Box nearby! Grab it before it's gone."

    print(f"--- MOCK FIREBASE NOTIFICATION ---")
    print(f"Sending to {len(students)} students within 2km radius.")
    print(f"Title: {message_title}")
    print(f"Body: {message_body}")
    print(f"----------------------------------")

    # The real Firebase code would look like this:
    # message = messaging.MulticastMessage(
    #     notification=messaging.Notification(
    #         title=message_title,
    #         body=message_body,
    #     ),
    #     data={"deal_id": str(deal_id)},
    #     tokens=tokens,
    # )
    # response = messaging.send_multicast(message)
    # print(f"Successfully sent {response.success_count} messages")
