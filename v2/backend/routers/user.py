from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field

from auth import get_current_user
from db import execute_sp
from schemas.common import success

router = APIRouter(prefix="/api", tags=["user"])


class CreateRequestPayload(BaseModel):
    roleIds: list[int] = Field(min_length=1)
    durationMinutes: int = Field(gt=0)
    justification: str = ""
    ticketRef: str | None = None


@router.get("/user/grants")
def user_grants(user=Depends(get_current_user)):
    rows = execute_sp("jit.sp_Grant_ListActiveForUser", {"UserId": user["UserId"]})
    return success(rows or [])


@router.get("/user/requests")
def user_requests(user=Depends(get_current_user)):
    rows = execute_sp("jit.sp_Request_ListForUser", {"UserId": user["UserId"]})
    return success(rows or [])


@router.get("/roles/requestable")
def requestable_roles(user=Depends(get_current_user)):
    rows = execute_sp("jit.sp_Role_ListRequestable", {"UserId": user["UserId"]})
    return success(rows or [])


@router.post("/requests")
def create_request(payload: CreateRequestPayload, user=Depends(get_current_user)):
    role_ids = ",".join([str(r) for r in payload.roleIds])
    execute_sp(
        "jit.sp_Request_Create",
        {
            "UserId": user["UserId"],
            "RoleIds": role_ids,
            "RequestedDurationMinutes": payload.durationMinutes,
            "Justification": payload.justification,
            "TicketRef": payload.ticketRef,
        },
        fetch=False,
    )
    return success(message="Request submitted successfully.")


@router.post("/requests/{request_id}/cancel")
def cancel_request(request_id: int, user=Depends(get_current_user)):
    execute_sp("jit.sp_Request_Cancel", {"RequestId": request_id, "UserId": user["UserId"]}, fetch=False)
    return success(message="Request cancelled successfully.")


@router.post("/requests/{request_id}/approve")
def approve_request(request_id: int, payload: dict | None = None, user=Depends(get_current_user)):
    if not (user.get("IsApprover") or user.get("IsDataSteward") or user.get("IsAdmin")):
        raise HTTPException(status_code=403, detail="Approver access required.")
    comment = (payload or {}).get("comment", "")
    execute_sp(
        "jit.sp_Request_Approve",
        {"RequestId": request_id, "ApproverUserId": user["UserId"], "DecisionComment": comment},
        fetch=False,
    )
    return success(message="Request approved successfully.")


@router.post("/requests/{request_id}/deny")
def deny_request(request_id: int, payload: dict, user=Depends(get_current_user)):
    if not (user.get("IsApprover") or user.get("IsDataSteward") or user.get("IsAdmin")):
        raise HTTPException(status_code=403, detail="Approver access required.")
    comment = (payload or {}).get("comment", "").strip()
    if not comment:
        raise HTTPException(status_code=400, detail="A reason is required when denying a request.")
    execute_sp(
        "jit.sp_Request_Deny",
        {"RequestId": request_id, "ApproverUserId": user["UserId"], "DecisionComment": comment},
        fetch=False,
    )
    return success(message="Request denied.")

