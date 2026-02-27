from fastapi import APIRouter, Depends, HTTPException

from auth import get_current_user, require_approver
from db import execute_sp
from schemas.common import success

router = APIRouter(prefix="/api/approver", tags=["approver"])


@router.get("/pending")
def pending(user=Depends(get_current_user)):
    require_approver(user)
    rows = execute_sp("jit.sp_Request_ListPendingForApprover", {"ApproverUserId": user["UserId"]})
    return success(rows or [])


@router.get("/requests/{request_id}")
def request_detail(request_id: int, user=Depends(get_current_user)):
    # NOTE: Candidate for removal. Current UI is fully served by /pending,
    # and this endpoint currently exists for optional future drill-down UX.
    require_approver(user)
    pending_rows = execute_sp("jit.sp_Request_ListPendingForApprover", {"ApproverUserId": user["UserId"]}) or []
    detail = next((row for row in pending_rows if int(row.get("RequestId", -1)) == request_id), None)
    roles = execute_sp("jit.sp_Request_GetRoles", {"RequestId": request_id})
    if detail is None:
        raise HTTPException(status_code=404, detail="Request not found in approver pending queue.")
    detail["Roles"] = roles or []
    return success(detail)

