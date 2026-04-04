"""
In-memory cache implementation for development.
Provides a simple key-value store that mimics Redis interface.
"""
import json
import time
from typing import Optional, Any

class InMemoryCache:
    """Simple in-memory cache with expiration support."""
    
    def __init__(self):
        self.store = {}
        self.expiry = {}
    
    def set(self, key: str, value: Any, ex: Optional[int] = None) -> None:
        """Set a key-value pair with optional expiration time (in seconds)."""
        self.store[key] = value
        if ex:
            self.expiry[key] = time.time() + ex
    
    def get(self, key: str) -> Optional[Any]:
        """Get a value by key. Returns None if expired or not found."""
        # Check if key has expired
        if key in self.expiry:
            if time.time() > self.expiry[key]:
                del self.store[key]
                del self.expiry[key]
                return None
        
        return self.store.get(key)
    
    def delete(self, key: str) -> None:
        """Delete a key."""
        self.store.pop(key, None)
        self.expiry.pop(key, None)
    
    def __repr__(self):
        return f"<InMemoryCache with {len(self.store)} keys>"


# Global cache instance
cache = InMemoryCache()
