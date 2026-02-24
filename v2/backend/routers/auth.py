from fastapi import APIRouter, Depends

from auth import get_current_user
from schemas.common import success

router = APIRouter(prefix="/api", tags=["auth"])


@router.get("/me")
def me(user=Depends(get_current_user)):
    return success(user)

