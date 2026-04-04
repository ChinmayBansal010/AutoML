from slowapi import Limiter
from slowapi.util import get_remote_address

"""
Create a global limiter object.
We use get_remote_address to identify users by their IP address.
"""
limiter = Limiter(key_func=get_remote_address)