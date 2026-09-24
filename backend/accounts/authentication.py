import jwt
from django.conf import settings
from django.contrib.auth import get_user_model
from rest_framework.authentication import BaseAuthentication, get_authorization_header
from rest_framework.exceptions import AuthenticationFailed


FIREBASE_ISSUER = f"https://securetoken.google.com/{settings.FIREBASE_PROJECT_ID}"
FIREBASE_KEYS = jwt.PyJWKClient(
    'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com'
)


class FirebaseAuthentication(BaseAuthentication):
    """Verify Firebase ID tokens and link them to the app's existing user data."""

    def authenticate(self, request):
        parts = get_authorization_header(request).split()
        if not parts or parts[0].lower() != b'bearer':
            return None
        if len(parts) != 2:
            raise AuthenticationFailed('Invalid authorization header.')

        try:
            token = parts[1].decode('utf-8')
            unverified = jwt.decode(token, options={'verify_signature': False})
            # Leave legacy Django JWTs for SimpleJWTAuthentication to process.
            if unverified.get('iss') != FIREBASE_ISSUER:
                return None

            signing_key = FIREBASE_KEYS.get_signing_key_from_jwt(token).key
            claims = jwt.decode(
                token,
                signing_key,
                algorithms=['RS256'],
                audience=settings.FIREBASE_PROJECT_ID,
                issuer=FIREBASE_ISSUER,
            )
        except (jwt.PyJWTError, UnicodeDecodeError, ValueError) as error:
            raise AuthenticationFailed('Invalid or expired Firebase session.') from error
        except Exception as error:
            # Includes network failures while refreshing Google's public keys.
            raise AuthenticationFailed('Could not verify the Firebase session.') from error

        email = claims.get('email')
        if not email:
            raise AuthenticationFailed('A verified email address is required.')

        user_model = get_user_model()
        user, created = user_model.objects.get_or_create(
            email=user_model.objects.normalize_email(email),
            defaults={
                'name': claims.get('name') or email.split('@', 1)[0],
            },
        )
        if created:
            user.set_unusable_password()
            user.save(update_fields=['password'])
        if not user.is_active:
            raise AuthenticationFailed('This account is disabled.')
        return user, claims

    def authenticate_header(self, request):
        return 'Bearer'
